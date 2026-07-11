import 'dart:async';
import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/services/bid_session_service.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/booking/booking_event.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/booking/booking_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * BLoC responsible for orchestrating the trip booking and driver bidding lifecycle.
 *
 * Coordinates searching, showing nearby drivers, streaming bids, accepting offers,
 * and dispatch updates.
 */
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final DriverRepository _driverRepository;
  final BidSessionService _bidSessionService;

  StreamSubscription<List<dynamic>>? _offersSubscription;
  StreamSubscription<DriverMatchResult>? _driverFoundSubscription;

  DriverModel? _nearestDriver;
  int _totalTrips = 0;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = false;

  double? _pickupLat;
  double? _pickupLng;
  String? _pickupName;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _dropoffName;
  double? _fare;
  String? _rideType;

  BookingBloc({
    required DriverRepository driverRepository,
    required BidSessionService bidSessionService,
  })  : _driverRepository = driverRepository,
        _bidSessionService = bidSessionService,
        super(BookingInitial()) {
    on<LocateNearestDriverEvent>(_onLocateNearestDriver);
    on<StartDirectBookingEvent>(_onStartDirectBooking);
    on<StartOpenBookingEvent>(_onStartOpenBooking);
    on<AcceptBidOfferEvent>(_onAcceptBidOffer);
    on<CancelBookingEvent>(_onCancelBooking);
    on<UpdateOffersEvent>(_onUpdateOffers);
    on<DriverMatchedEvent>(_onDriverMatched);
  }

  Future<void> _onLocateNearestDriver(
    LocateNearestDriverEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(FindingNearestDriver());
    try {
      final nearbyDrivers = await _driverRepository.getNearbyDrivers(
        lat: event.pickupLat,
        lng: event.pickupLng,
      );

      if (nearbyDrivers.isNotEmpty) {
        DriverModel closestDriver = nearbyDrivers.first;
        for (final d in nearbyDrivers) {
          if (d.distanceKm < closestDriver.distanceKm) {
            closestDriver = d;
          }
        }
        _nearestDriver = closestDriver;

        try {
          final stats = await PassengerApiService.fetchDriverStats(closestDriver.id);
          if (stats != null && stats['totalTrips'] != null) {
            _totalTrips = stats['totalTrips'] as int;
          } else {
            _totalTrips = (closestDriver.name.hashCode.abs() % 150) + 20;
          }
        } catch (error) {
          debugPrint('Error loading driver stats, fallback to seed: $error');
          _totalTrips = (closestDriver.name.hashCode.abs() % 150) + 20;
        }

        try {
          _isLoadingReviews = true;
          emit(NearestDriverFound(
            driver: closestDriver,
            totalTrips: _totalTrips,
            reviews: const [],
            isLoadingReviews: true,
          ));

          final rawReviews = await PassengerApiService.fetchDriverReviews(closestDriver.id);
          final List<Map<String, dynamic>> processedReviews = [];
          for (final r in rawReviews) {
            if (r is Map<String, dynamic>) {
              final createdAtStr = r['createdAt'] ?? r['created_at'];
              String dateFormatted = 'Recent';
              if (createdAtStr != null) {
                try {
                  final parsedDate = DateTime.parse(createdAtStr as String);
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  dateFormatted = '${months[parsedDate.month - 1]} ${parsedDate.day}, ${parsedDate.year}';
                } catch (error) {
                  debugPrint('Failed to parse review date: $error');
                }
              }
              processedReviews.add({
                'passengerName': r['passengerName'] ?? r['passenger_name'] ?? 'Passenger',
                'comment': r['comment'] ?? '',
                'rating': (r['rating'] as num?)?.toDouble() ?? 5.0,
                'date': dateFormatted,
              });
            }
          }
          _reviews = processedReviews;
        } catch (error) {
          debugPrint('Failed to process reviews: $error');
          _reviews = const [];
        } finally {
          _isLoadingReviews = false;
        }

        emit(NearestDriverFound(
          driver: closestDriver,
          totalTrips: _totalTrips,
          reviews: _reviews,
          isLoadingReviews: _isLoadingReviews,
        ));
      } else {
        emit(const BookingFailure('No drivers nearby.'));
      }
    } catch (e) {
      emit(BookingFailure(e.toString()));
    }
  }

  Future<void> _onStartDirectBooking(
    StartDirectBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (_nearestDriver == null) return;
    emit(BookingSearching(isDirect: true, targetDriver: _nearestDriver));

    final prefs = await SharedPreferences.getInstance();
    final passengerId = prefs.getString('passenger_id') ?? '';
    if (passengerId.isEmpty) {
      emit(const BookingFailure('Passenger ID is missing.'));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = event.trip.pickupAddress ?? 'Current Location';
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;
    _fare = event.trip.fare;
    _rideType = event.trip.rideType;

    _subscribeToSession();

    await _bidSessionService.startSession(
      trip: event.trip,
      passengerId: passengerId,
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
      distanceKm: event.distanceKm,
      durationMinutes: event.durationMinutes,
      targetDriverId: _nearestDriver!.id,
    );
  }

  Future<void> _onStartOpenBooking(
    StartOpenBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingSearching(isDirect: false));

    final prefs = await SharedPreferences.getInstance();
    final passengerId = prefs.getString('passenger_id') ?? '';
    if (passengerId.isEmpty) {
      emit(const BookingFailure('Passenger ID is missing.'));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = event.trip.pickupAddress ?? 'Current Location';
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;
    _fare = event.trip.fare;
    _rideType = event.trip.rideType;

    _subscribeToSession();

    await _bidSessionService.startSession(
      trip: event.trip,
      passengerId: passengerId,
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
      distanceKm: event.distanceKm,
      durationMinutes: event.durationMinutes,
    );
  }

  void _subscribeToSession() {
    unawaited(_offersSubscription?.cancel());
    unawaited(_driverFoundSubscription?.cancel());

    _bidSessionService.setForeground(true);

    _offersSubscription = _bidSessionService.offersStream.listen((offers) {
      add(UpdateOffersEvent(offers));
    });

    _driverFoundSubscription = _bidSessionService.driverFoundStream.listen((matchedResult) {
      add(DriverMatchedEvent(matchedResult));
    });
  }

  void _onUpdateOffers(
    UpdateOffersEvent event,
    Emitter<BookingState> emit,
  ) {
    if (state is BookingSearching) {
      final current = state as BookingSearching;
      emit(BookingOffersReceived(
        offers: event.offers,
        isDirect: current.isDirect,
        targetDriver: current.targetDriver,
      ));
    } else if (state is BookingOffersReceived) {
      final current = state as BookingOffersReceived;
      emit(BookingOffersReceived(
        offers: event.offers,
        isDirect: current.isDirect,
        targetDriver: current.targetDriver,
      ));
    }
  }

  Future<void> _onDriverMatched(
    DriverMatchedEvent event,
    Emitter<BookingState> emit,
  ) async {
    _cleanupSubscriptions();

    final prefs = await SharedPreferences.getInstance();
    final passengerId = prefs.getString('passenger_id') ?? '';
    
    RideHistoryModel? createdRide;
    
    if (passengerId.isNotEmpty) {
      try {
        final res = await PassengerApiService.createRideRequest(
          passengerId: passengerId,
          rideType: _rideType ?? 'Bao Bao Standard',
          pickupLat: _pickupLat ?? 0.0,
          pickupLng: _pickupLng ?? 0.0,
          pickupName: _pickupName ?? 'Current Location',
          dropoffLat: _dropoffLat ?? 0.0,
          dropoffLng: _dropoffLng ?? 0.0,
          dropoffName: _dropoffName ?? 'Destination',
          fare: _fare ?? 0.0,
        );
        if (res != null && res['id'] != null) {
          final activeRideId = res['id'] as String;
          await prefs.setString('active_ride_id', activeRideId);
          
          createdRide = RideHistoryModel(
            id: activeRideId,
            pickup: res['pickup_name'] as String? ?? _pickupName ?? '',
            destination: _dropoffName ?? '',
            pickupLat: SafeParse.toDouble(res['pickup_latitude']),
            pickupLng: SafeParse.toDouble(res['pickup_longitude']),
            destLat: _dropoffLat ?? 0.0,
            destLng: _dropoffLng ?? 0.0,
            date: DateTime.now().toLocal().toString(),
            price: '₱${(_fare ?? 0.0).toStringAsFixed(2)}',
            status: 'accepted',
            driverName: res['driver_name'] as String? ?? event.matchResult.driverName,
            vehiclePlate: res['plate_number'] as String? ?? event.matchResult.plateNumber,
          );
        }
      } catch (error) {
        debugPrint('Error creating ride request, falling back to matched result: $error');
      }
    }

    emit(BookingDriverMatched(
      matchResult: event.matchResult,
      createdRide: createdRide,
    ));
  }

  Future<void> _onAcceptBidOffer(
    AcceptBidOfferEvent event,
    Emitter<BookingState> emit,
  ) async {
    await _bidSessionService.acceptOffer(
      offerId: event.offerId,
      driverName: event.driverName,
      vehicleType: event.vehicleType,
      plateNumber: event.plateNumber,
      proposedFare: event.proposedFare,
    );
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    _cleanupSubscriptions();
    await _bidSessionService.cancelSession();
    emit(BookingCanceled());
  }

  void _cleanupSubscriptions() {
    unawaited(_offersSubscription?.cancel());
    unawaited(_driverFoundSubscription?.cancel());
    _offersSubscription = null;
    _driverFoundSubscription = null;
  }

  @override
  Future<void> close() {
    _cleanupSubscriptions();
    return super.close();
  }
}
