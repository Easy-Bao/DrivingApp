import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_event.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_state.dart';
import 'package:shared_core/shared_core.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final IDriverRepository _driverRepository;
  final BiddingRemoteDataSource _biddingDataSource;
  final SecureSessionService _secureSessionService;
  final InboxCubit? _inboxCubit;

  StreamSubscription<List<dynamic>>? _offersSubscription;
  StreamSubscription<DriverMatchResult>? _driverFoundSubscription;

  DriverModel? _nearestDriver;
  int _totalTrips = 0;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = false;
  bool _nearestSearchCancelled = false;
  bool _noDriverNotificationSent = false;
  bool _isAutoAcceptingOffer = false;
  String? _activeBidSessionId;

  double? _pickupLat;
  double? _pickupLng;
  String? _pickupName;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _dropoffName;
  double? _fare;
  String? _rideType;

  Future<String> _resolvePickupName() async {
    final providedName = _pickupName?.trim();
    if (providedName != null &&
        providedName.isNotEmpty &&
        providedName != 'Current Location') {
      return providedName;
    }

    final lat = _pickupLat;
    final lng = _pickupLng;
    if (lat == null || lng == null) return providedName ?? 'Current Location';

    try {
      final place = await MapProvider.getPlaceFromCoordinates(lat, lng);
      final resolvedName = place?.fullAddress.trim();
      return resolvedName == null || resolvedName.isEmpty
          ? providedName ?? 'Current Location'
          : resolvedName;
    } catch (_) {
      return providedName ?? 'Current Location';
    }
  }

  BookingBloc({
    required IDriverRepository driverRepository,
    required BiddingRemoteDataSource biddingDataSource,
    required SecureSessionService secureSessionService,
    InboxCubit? inboxCubit,
  }) : _driverRepository = driverRepository,
       _biddingDataSource = biddingDataSource,
       _secureSessionService = secureSessionService,
       _inboxCubit = inboxCubit,
       super(BookingInitial()) {
    on<LocateNearestDriverEvent>(_onLocateNearestDriver);
    on<StartDirectBookingEvent>(_onStartDirectBooking);
    on<StartOpenBookingEvent>(_onStartOpenBooking);
    on<AcceptBidOfferEvent>(_onAcceptBidOffer);
    on<CancelBookingEvent>(_onCancelBooking);
    on<UpdateOffersEvent>(_onUpdateOffers);
    on<DriverMatchedEvent>(_onDriverMatched);
  }

  bool get hasActiveDriverSearch =>
      state is FindingNearestDriver ||
      state is NearestDriverFound ||
      state is BookingSearching ||
      state is BookingOffersReceived;

  Future<void> _onLocateNearestDriver(
    LocateNearestDriverEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveDriverSearch) return;
    _nearestSearchCancelled = false;
    _noDriverNotificationSent = false;
    _isAutoAcceptingOffer = false;
    emit(
      FindingNearestDriver(
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
      ),
    );

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
      if (!_nearestSearchCancelled) {
        _notifyNoDriverFound();
      }
      if (isClosed || _nearestSearchCancelled) return;
      emit(
        BookingFailure(
          lastFailure?.message ?? 'No drivers nearby. Please try again.',
          isNoDriverFound: true,
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
      if (stats['totalTrips'] != null) {
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
          trip: event.trip,
          pickupLat: event.pickupLat,
          pickupLng: event.pickupLng,
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
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
      ),
    );
  }

  void _notifyNoDriverFound() {
    final inboxCubit = _inboxCubit;
    if (_noDriverNotificationSent ||
        inboxCubit == null ||
        inboxCubit.isClosed) {
      return;
    }
    _noDriverNotificationSent = true;
    inboxCubit.addLocalNotification(
      InboxNotification(
        id: 'no-driver-${DateTime.now().millisecondsSinceEpoch}',
        title: 'No driver found',
        message:
            'We could not find a driver for your ride. You can try again from the home screen.',
        timestamp: DateTime.now(),
        type: 'driver',
        isRead: false,
      ),
    );
  }

  Future<void> _onStartDirectBooking(
    StartDirectBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (_nearestDriver == null) return;
    _isAutoAcceptingOffer = false;
    emit(BookingSearching(isDirect: true, targetDriver: _nearestDriver));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      emit(const BookingFailure('Passenger ID is missing.'));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = event.trip.pickupAddress ?? 'Current Location';
    _pickupName = await _resolvePickupName();
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;
    _fare = event.trip.fare;
    _rideType = event.trip.rideType;

    try {
      final response = await _biddingDataSource.requestRide({
        'passenger_id': passengerId,
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
      final sessionId = response['id'] as String?;
      if (sessionId == null || sessionId.isEmpty) {
        throw StateError('Booking session was not created');
      }
      _activeBidSessionId = sessionId;
      _subscribeToSession(sessionId);
    } catch (error) {
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> _onStartOpenBooking(
    StartOpenBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingSearching(isDirect: false));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      emit(const BookingFailure('Passenger ID is missing.'));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = event.trip.pickupAddress ?? 'Current Location';
    _pickupName = await _resolvePickupName();
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;
    _fare = event.trip.fare;
    _rideType = event.trip.rideType;

    try {
      final response = await _biddingDataSource.requestRide({
        'passenger_id': passengerId,
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
      final sessionId = response['id'] as String?;
      if (sessionId == null || sessionId.isEmpty) {
        throw StateError('Booking session was not created');
      }
      _activeBidSessionId = sessionId;
      _subscribeToSession(sessionId);
    } catch (error) {
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
  }

  void _subscribeToSession(String sessionId) {
    unawaited(_offersSubscription?.cancel());
    unawaited(_driverFoundSubscription?.cancel());

    _offersSubscription = Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) async {
          try {
            return await _biddingDataSource.fetchOffers(sessionId);
          } catch (error) {
            dev.log('Failed to poll booking offers: $error');
            return const <dynamic>[];
          }
        })
        .listen((offers) {
          add(UpdateOffersEvent(offers));
        });
  }

  void _onUpdateOffers(UpdateOffersEvent event, Emitter<BookingState> emit) {
    final isDirectBooking = switch (state) {
      BookingSearching(:final isDirect) => isDirect,
      BookingOffersReceived(:final isDirect) => isDirect,
      _ => false,
    };

    if (isDirectBooking && event.offers.isNotEmpty && !_isAutoAcceptingOffer) {
      final pendingOffer = event.offers
          .whereType<Map<String, dynamic>>()
          .where((offer) => offer['status'] == 'pending')
          .firstWhere((_) => true, orElse: () => <String, dynamic>{});
      final offerId = pendingOffer['id'] as String? ?? '';
      if (offerId.isNotEmpty) {
        _isAutoAcceptingOffer = true;
        add(
          AcceptBidOfferEvent(
            offerId: offerId,
            driverId: pendingOffer['driver_id'] as String? ?? '',
            driverName: pendingOffer['driver_name'] as String? ?? 'Driver',
            vehicleType: pendingOffer['vehicle_type'] as String? ?? 'Bao Bao',
            plateNumber: pendingOffer['plate_number'] as String? ?? '',
            proposedFare:
                (pendingOffer['proposed_fare'] as num?)?.toDouble() ??
                _fare ??
                0.0,
          ),
        );
        return;
      }
    }

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
    _nearestSearchCancelled = true;
    _cleanupSubscriptions();

    final passengerId = await _secureSessionService.readPassengerId() ?? '';

    RideHistoryModel? createdRide;

    if (passengerId.isNotEmpty) {
      try {
        final res = await _biddingDataSource.requestRide({
          'passenger_id': passengerId,
          'ride_type': _rideType ?? '',
          'pickup_latitude': _pickupLat ?? 0.0,
          'pickup_longitude': _pickupLng ?? 0.0,
          'pickup_name': _pickupName ?? 'Current Location',
          'dropoff_latitude': _dropoffLat ?? 0.0,
          'dropoff_longitude': _dropoffLng ?? 0.0,
          'dropoff_name': _dropoffName ?? 'Destination',
          'fare': _fare ?? 0.0,
        });
        if (res['id'] != null) {
          final activeRideId = res['id']?.toString() ?? '';
          await _secureSessionService.saveActiveRideId(activeRideId);

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
            status: RideStatus.accepted.value,
            driverId: res['driver_id'] as String? ?? event.matchResult.driverId,
            driverName:
                res['driver_name'] as String? ?? event.matchResult.driverName,
            vehiclePlate:
                res['plate_number'] as String? ?? event.matchResult.plateNumber,
            vehicleType:
                res['vehicle_type'] as String? ?? event.matchResult.vehicleType,
          );
        }
      } catch (error) {
        dev.log(
          'Error creating ride request, falling back to matched result: $error',
        );
      }
    }

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
    final sessionId = _activeBidSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      emit(const BookingFailure('Booking session is no longer available.'));
      return;
    }

    try {
      final response = await _biddingDataSource.acceptOffer(
        sessionId: sessionId,
        offerId: event.offerId,
      );
      final rideId = response['rideId'] as String? ?? '';
      if (rideId.isEmpty) {
        throw StateError('Accepted booking did not return a ride ID');
      }

      await _secureSessionService.saveActiveRideId(rideId);
      _cleanupSubscriptions();
      emit(
        BookingDriverMatched(
          matchResult: DriverMatchResult(
            driverId: event.driverId,
            driverName: event.driverName,
            vehicleType: event.vehicleType,
            plateNumber: event.plateNumber,
            proposedFare: event.proposedFare,
          ),
          createdRide: RideHistoryModel(
            id: rideId,
            pickup: _pickupName ?? 'Current Location',
            destination: _dropoffName ?? 'Destination',
            pickupLat: _pickupLat ?? 0.0,
            pickupLng: _pickupLng ?? 0.0,
            destLat: _dropoffLat ?? 0.0,
            destLng: _dropoffLng ?? 0.0,
            date: DateTime.now().toLocal().toString(),
            price: '₱${event.proposedFare.toStringAsFixed(2)}',
            status: RideStatus.accepted.value,
            driverId: event.driverId,
            driverName: event.driverName,
            vehiclePlate: event.plateNumber,
            vehicleType: event.vehicleType,
          ),
        ),
      );
    } catch (error) {
      _isAutoAcceptingOffer = false;
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    _nearestSearchCancelled = true;
    _cleanupSubscriptions();
    final sessionId = _activeBidSessionId;
    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        await _biddingDataSource
            .cancelSession(sessionId)
            .timeout(const Duration(seconds: 5));
      }
    } catch (error) {
      dev.log('Unable to confirm booking cancellation: $error');
    }
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
