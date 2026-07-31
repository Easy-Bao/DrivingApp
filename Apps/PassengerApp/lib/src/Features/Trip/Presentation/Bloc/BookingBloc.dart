import 'dart:async';
import 'dart:developer' as dev;

import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Features/Booking/Data/DataSources/BiddingRemoteDataSource.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/BookingEvent.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/BookingState.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final DriverRepository _driverRepository;
  final BiddingRemoteDataSource _biddingDataSource;

  StreamSubscription<void>? _sessionSubscription;
  String? _sessionId;

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

  BookingBloc({
    required DriverRepository driverRepository,
    required BiddingRemoteDataSource biddingDataSource,
  }) : _driverRepository = driverRepository,
       _biddingDataSource = biddingDataSource,
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

    List<DriverModel> nearbyDrivers = [];
    Failure? lastFailure;

    for (int attempt = 0; attempt < 5; attempt++) {
      final result = await _driverRepository.getNearbyDrivers(
        lat: event.pickupLat,
        lng: event.pickupLng,
      );

      result.fold(
        (failure) {
          lastFailure = failure;
        },
        (drivers) {
          nearbyDrivers = drivers;
        },
      );

      if (nearbyDrivers.isNotEmpty) break;
      await Future.delayed(const Duration(seconds: 2));
    }

    if (nearbyDrivers.isEmpty) {
      emit(
        BookingFailure(
          lastFailure?.message ?? 'No drivers nearby. Please try again.',
        ),
      );
      return;
    }

    DriverModel closestDriver = nearbyDrivers.first;
    for (final d in nearbyDrivers) {
      if (d.distanceKm < closestDriver.distanceKm) {
        closestDriver = d;
      }
    }
    _nearestDriver = closestDriver;

    try {
      final stats = await _biddingDataSource.fetchDriverStats(closestDriver.id);
      if (stats != null && stats['totalTrips'] != null) {
        _totalTrips = stats['totalTrips'] as int;
      } else {
        _totalTrips = (closestDriver.name.hashCode.abs() % 150) + 20;
      }
    } catch (error) {
      dev.log('Error loading driver stats, fallback to seed: $error');
      _totalTrips = (closestDriver.name.hashCode.abs() % 150) + 20;
    }

    try {
      _isLoadingReviews = true;
      emit(
        NearestDriverFound(
          driver: closestDriver,
          nearbyDrivers: nearbyDrivers,
          totalTrips: _totalTrips,
          reviews: const [],
          isLoadingReviews: true,
        ),
      );

      final rawReviews = await _biddingDataSource.fetchDriverReviews(
        closestDriver.id,
      );
      final List<Map<String, dynamic>> processedReviews = [];
      for (final r in rawReviews) {
        if (r is Map<String, dynamic>) {
          final createdAtStr = r['createdAt'] ?? r['created_at'];
          String dateFormatted = 'Recent';
          if (createdAtStr != null) {
            try {
              final parsedDate = DateTime.parse(createdAtStr.toString());
              final months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];
              dateFormatted =
                  '${months[parsedDate.month - 1]} ${parsedDate.day}, ${parsedDate.year}';
            } catch (error) {
              dev.log('Failed to parse review date: $error');
            }
          }
          processedReviews.add({
            'passengerName':
                r['passengerName'] ?? r['passenger_name'] ?? 'Passenger',
            'comment': r['comment'] ?? '',
            'rating': (r['rating'] as num?)?.toDouble() ?? 5.0,
            'date': dateFormatted,
          });
        }
      }
      _reviews = processedReviews;
    } catch (error) {
      dev.log('Failed to process reviews: $error');
      _reviews = const [];
    } finally {
      _isLoadingReviews = false;
    }

    emit(
      NearestDriverFound(
        driver: closestDriver,
        nearbyDrivers: nearbyDrivers,
        totalTrips: _totalTrips,
        reviews: _reviews,
        isLoadingReviews: _isLoadingReviews,
      ),
    );
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

    try {
      final session = await _biddingDataSource.requestRide({
        'ride_type': event.trip.rideType,
        'pickup_latitude': event.pickupLat,
        'pickup_longitude': event.pickupLng,
        'pickup_name': _pickupName,
        'dropoff_latitude': _dropoffLat,
        'dropoff_longitude': _dropoffLng,
        'dropoff_name': _dropoffName,
        'distance_km': event.distanceKm,
        'duration_minutes': event.durationMinutes,
        'target_driver_id': _nearestDriver!.id,
      });
      _startSessionPolling(session);
    } catch (error) {
      emit(
        BookingFailure(
          passengerRideErrorMessage(
            _takeRemotePublicError() ?? ErrorHandler.getErrorMessage(error),
          ),
        ),
      );
    }
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

    try {
      final session = await _biddingDataSource.requestRide({
        'ride_type': event.trip.rideType,
        'pickup_latitude': event.pickupLat,
        'pickup_longitude': event.pickupLng,
        'pickup_name': _pickupName,
        'dropoff_latitude': _dropoffLat,
        'dropoff_longitude': _dropoffLng,
        'dropoff_name': _dropoffName,
        'distance_km': event.distanceKm,
        'duration_minutes': event.durationMinutes,
      });
      _startSessionPolling(session);
    } catch (error) {
      emit(
        BookingFailure(
          passengerRideErrorMessage(
            _takeRemotePublicError() ?? ErrorHandler.getErrorMessage(error),
          ),
        ),
      );
    }
  }

  void _startSessionPolling(Map<String, dynamic> session) {
    final sessionId = session['id']?.toString() ?? '';
    if (sessionId.isEmpty) {
      throw const FormatException(
        'Bid session response did not include an ID.',
      );
    }
    _sessionId = sessionId;
    unawaited(_sessionSubscription?.cancel());
    _sessionSubscription =
        Stream<int>.periodic(const Duration(seconds: 3), (tick) => tick)
            .asyncMap((_) => _pollSession(sessionId))
            .listen(
              null,
              onError: (Object error) {
                dev.log('Unable to refresh bid session $sessionId: $error');
              },
            );
  }

  Future<void> _pollSession(String sessionId) async {
    final offers = await _biddingDataSource.fetchOffers(sessionId);
    add(UpdateOffersEvent(offers));

    final session = await _biddingDataSource.getSession(sessionId);
    if (session['status'] != 'accepted') return;

    final rideId = acceptedRideId(session);
    final acceptedDriverId = session['accepted_driver_id']?.toString();
    final acceptedOffer = offers.whereType<Map>().firstWhere(
      (offer) => offer['driver_id']?.toString() == acceptedDriverId,
      orElse: () => const <String, dynamic>{},
    );
    if (rideId == null || acceptedOffer.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_ride_id', rideId);
    add(
      DriverMatchedEvent(
        DriverMatchResult(
          driverId: acceptedDriverId ?? '',
          driverName: acceptedOffer['driver_name']?.toString() ?? 'Driver',
          vehicleType: acceptedOffer['vehicle_type']?.toString() ?? 'Bao Bao',
          plateNumber: acceptedOffer['plate_number']?.toString() ?? 'Unknown',
          proposedFare:
              (acceptedOffer['proposed_fare'] as num?)?.toDouble() ??
              (_fare ?? 0),
        ),
      ),
    );
  }

  void _onUpdateOffers(UpdateOffersEvent event, Emitter<BookingState> emit) {
    if (state is BookingSearching) {
      final current = state as BookingSearching;
      emit(
        BookingOffersReceived(
          offers: event.offers,
          isDirect: current.isDirect,
          targetDriver: current.targetDriver,
        ),
      );
    } else if (state is BookingOffersReceived) {
      final current = state as BookingOffersReceived;
      emit(
        BookingOffersReceived(
          offers: event.offers,
          isDirect: current.isDirect,
          targetDriver: current.targetDriver,
        ),
      );
    }
  }

  Future<void> _onDriverMatched(
    DriverMatchedEvent event,
    Emitter<BookingState> emit,
  ) async {
    _cleanupSubscriptions();

    final prefs = await SharedPreferences.getInstance();
    final activeRideId = prefs.getString('active_ride_id') ?? '';
    if (activeRideId.isEmpty) {
      emit(
        const BookingFailure(
          'The ride assignment did not finish. Please request the ride again.',
        ),
      );
      return;
    }

    Map<String, dynamic>? ride;
    try {
      ride = await _biddingDataSource.getRideStatus(activeRideId);
    } catch (error) {
      dev.log('Unable to refresh accepted ride $activeRideId: $error');
    }
    final createdRide = RideHistoryModel(
      id: activeRideId,
      pickup: ride?['pickup_name'] as String? ?? _pickupName ?? '',
      destination: ride?['dropoff_name'] as String? ?? _dropoffName ?? '',
      pickupLat: SafeParse.toDouble(ride?['pickup_latitude'] ?? _pickupLat),
      pickupLng: SafeParse.toDouble(ride?['pickup_longitude'] ?? _pickupLng),
      destLat: SafeParse.toDouble(ride?['dropoff_latitude'] ?? _dropoffLat),
      destLng: SafeParse.toDouble(ride?['dropoff_longitude'] ?? _dropoffLng),
      date: DateTime.now().toLocal().toString(),
      price: '₱${(_fare ?? event.matchResult.proposedFare).toStringAsFixed(2)}',
      status: RideStatus.accepted.value,
      driverId: ride?['driver_id'] as String? ?? event.matchResult.driverId,
      driverName:
          ride?['driver_name'] as String? ?? event.matchResult.driverName,
      vehiclePlate:
          ride?['plate_number'] as String? ?? event.matchResult.plateNumber,
      vehicleType:
          ride?['vehicle_type'] as String? ?? event.matchResult.vehicleType,
    );

    emit(
      BookingDriverMatched(
        matchResult: event.matchResult,
        createdRide: createdRide,
      ),
    );
  }

  Future<void> _onAcceptBidOffer(
    AcceptBidOfferEvent event,
    Emitter<BookingState> emit,
  ) async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      emit(const BookingFailure('The booking session has expired.'));
      return;
    }

    try {
      final response = await _biddingDataSource.acceptOffer(
        sessionId: sessionId,
        offerId: event.offerId,
      );
      final rideId = acceptedRideId(response);
      if (rideId == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_ride_id', rideId);
      add(
        DriverMatchedEvent(
          DriverMatchResult(
            driverId: event.driverId,
            driverName: event.driverName,
            vehicleType: event.vehicleType,
            plateNumber: event.plateNumber,
            proposedFare: event.proposedFare,
          ),
        ),
      );
    } catch (error) {
      emit(
        BookingFailure(
          passengerRideErrorMessage(
            _takeRemotePublicError() ?? ErrorHandler.getErrorMessage(error),
          ),
        ),
      );
    }
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    final sessionId = _sessionId;
    _cleanupSubscriptions();
    if (sessionId != null) {
      try {
        await _biddingDataSource.cancelSession(sessionId);
      } catch (error) {
        emit(
          BookingFailure(
            passengerRideErrorMessage(
              _takeRemotePublicError() ?? ErrorHandler.getErrorMessage(error),
            ),
          ),
        );
        return;
      }
    }
    emit(BookingCanceled());
  }

  void _cleanupSubscriptions() {
    unawaited(_sessionSubscription?.cancel());
    _sessionSubscription = null;
    _sessionId = null;
  }

  String? _takeRemotePublicError() => _biddingDataSource.takeLastPublicError();

  @override
  Future<void> close() {
    _cleanupSubscriptions();
    return super.close();
  }
}
