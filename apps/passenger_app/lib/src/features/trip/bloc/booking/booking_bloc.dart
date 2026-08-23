import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/driver_profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/trip/data/datasources/booking_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/entities/bid_session_trip.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_core/shared_core.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final IDriverRepository _driverRepository;
  final BookingRemoteDataSource _bookingDataSource;
  final DriverProfileRemoteDataSource _driverProfileDataSource;
  final SecureSessionService _secureSessionService;
  final BackgroundTelemetryService? _backgroundTelemetryService;
  final InboxCubit? _inboxCubit;
  final RealtimeWebSocketClient? _realtimeClient;
  final int _nearestDriverMaxAttempts;
  final Duration _nearestDriverRetryDelay;

  StreamSubscription<RealtimeEvent>? _realtimeEventsSubscription;
  StreamSubscription<RealtimeConnectionState>? _realtimeStateSubscription;

  int? _totalTrips;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = false;
  bool _nearestSearchCancelled = false;
  bool _noDriverNotificationSent = false;
  bool _isAutoAcceptingOffer = false;
  bool _realtimeWasConnected = false;
  String? _activeBidSessionId;

  double? _pickupLat;
  double? _pickupLng;
  String? _pickupName;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _dropoffName;

  String? _sessionIdFromResponse(Map<String, dynamic> response) {
    final rawSessionId = response['id'];
    final sessionId = switch (rawSessionId) {
      final String value => value.trim(),
      final num value => value.toInt().toString(),
      _ => null,
    };
    return sessionId == null || sessionId.isEmpty ? null : sessionId;
  }

  BookingBloc({
    required IDriverRepository driverRepository,
    required BookingRemoteDataSource bookingDataSource,
    required DriverProfileRemoteDataSource driverProfileDataSource,
    required SecureSessionService secureSessionService,
    InboxCubit? inboxCubit,
    BackgroundTelemetryService? backgroundTelemetryService,
    RealtimeWebSocketClient? realtimeClient,
    int nearestDriverMaxAttempts = 5,
    Duration nearestDriverRetryDelay = const Duration(seconds: 2),
  }) : assert(nearestDriverMaxAttempts > 0),
       _driverRepository = driverRepository,
       _bookingDataSource = bookingDataSource,
       _driverProfileDataSource = driverProfileDataSource,
       _secureSessionService = secureSessionService,
       _inboxCubit = inboxCubit,
       _backgroundTelemetryService = backgroundTelemetryService,
       _realtimeClient = realtimeClient,
       _nearestDriverMaxAttempts = nearestDriverMaxAttempts,
       _nearestDriverRetryDelay = nearestDriverRetryDelay,
       super(BookingInitial()) {
    on<LocateNearestDriverEvent>(
      _onLocateNearestDriver,
      transformer: (events, mapper) => events.exhaustMap(mapper),
    );
    on<StartDirectBookingEvent>(_onStartDirectBooking);
    on<StartOpenBookingEvent>(_onStartOpenBooking);
    on<AcceptBidOfferEvent>(_onAcceptBidOffer);
    on<CancelBookingEvent>(_onCancelBooking);
    on<ResetBookingEvent>(_onResetBooking);
    on<UpdateOffersEvent>(_onUpdateOffers);
    on<DriverMatchedEvent>(_onDriverMatched);
  }

  bool get hasActiveDriverSearch =>
      state is FindingNearestDriver ||
      state is NearestDriverFound ||
      state is BookingSearching ||
      state is BookingOffersReceived;

  bool get hasActiveBooking =>
      state is BookingSearching ||
      state is BookingOffersReceived ||
      state is BookingDriverMatched;

  Future<void> _onLocateNearestDriver(
    LocateNearestDriverEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveDriverSearch) return;
    _nearestSearchCancelled = false;
    _noDriverNotificationSent = false;
    _isAutoAcceptingOffer = false;
    _totalTrips = null;
    _reviews = const [];
    _isLoadingReviews = false;
    emit(
      FindingNearestDriver(
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
      ),
    );

    List<DriverModel> nearbyDrivers = [];
    Failure? lastFailure;
    var lastLookupSucceeded = false;

    for (int attempt = 0; attempt < _nearestDriverMaxAttempts; attempt++) {
      final result = await _driverRepository.getNearbyDrivers(
        lat: event.pickupLat,
        lng: event.pickupLng,
      );
      if (isClosed || _nearestSearchCancelled) return;

      result.fold(
        (failure) {
          lastFailure = failure;
          lastLookupSucceeded = false;
        },
        (drivers) {
          lastLookupSucceeded = true;
          lastFailure = null;
          nearbyDrivers = drivers;
        },
      );

      if (nearbyDrivers.isNotEmpty) break;
      if (!lastLookupSucceeded) break;
      if (attempt + 1 < _nearestDriverMaxAttempts) {
        await Future.delayed(_nearestDriverRetryDelay);
      }
      if (isClosed || _nearestSearchCancelled) return;
    }

    if (nearbyDrivers.isEmpty) {
      if (!lastLookupSucceeded && lastFailure != null) {
        emit(BookingFailure(ErrorHandler.getErrorMessage(lastFailure!)));
        return;
      }
      if (!_nearestSearchCancelled) {
        _notifyNoDriverFound();
      }
      if (isClosed || _nearestSearchCancelled) return;
      emit(
        BookingFailure(
          lastFailure == null
              ? 'No drivers nearby. Please try again.'
              : ErrorHandler.getErrorMessage(lastFailure!),
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
    _isLoadingReviews = true;
    emit(
      NearestDriverFound(
        driver: closestDriver,
        nearbyDrivers: nearbyDrivers,
        totalTrips: null,
        reviews: const [],
        isLoadingReviews: true,
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
      ),
    );

    int? loadedTotalTrips;
    List<Map<String, dynamic>> loadedReviews = const [];
    await Future.wait<void>([
      _loadDriverTripCount(closestDriver.id).then((value) {
        loadedTotalTrips = value;
      }),
      _loadDriverReviews(closestDriver.id).then((value) {
        loadedReviews = value;
      }),
    ]);
    if (isClosed || _nearestSearchCancelled) return;
    _totalTrips = loadedTotalTrips;
    _reviews = loadedReviews;
    _isLoadingReviews = false;

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

  Future<int?> _loadDriverTripCount(String driverId) async {
    try {
      final stats = await _driverProfileDataSource.fetchStats(driverId);
      final totalTrips = stats['totalTrips'] ?? stats['total_trips'];
      return (totalTrips as num?)?.toInt();
    } catch (error) {
      dev.log('Unable to load driver stats: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadDriverReviews(String driverId) async {
    try {
      final rawReviews = await _driverProfileDataSource.fetchReviews(driverId);
      final processedReviews = <Map<String, dynamic>>[];
      for (final review in rawReviews.whereType<Map<String, dynamic>>()) {
        processedReviews.add({
          'passengerName': review['passengerName'] ?? review['passenger_name'],
          'comment': review['comment'],
          'rating': (review['rating'] as num?)?.toDouble(),
          'date': _formatReviewDate(
            review['createdAt'] ?? review['created_at'],
          ),
        });
      }
      return processedReviews;
    } catch (error) {
      dev.log('Failed to process reviews: $error');
      return const [];
    }
  }

  String _formatReviewDate(Object? value) {
    if (value == null) return '';
    try {
      final date = DateTime.parse(value.toString());
      const months = [
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
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (error) {
      dev.log('Failed to parse review date: $error');
      return '';
    }
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
            'We could not find a driver for your ride. You can try searching again.',
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
    if (hasActiveBooking) return;
    final targetDriver = event.targetDriver;
    final targetDriverId = int.tryParse(targetDriver.id);
    if (targetDriverId == null || targetDriverId <= 0) {
      emit(const BookingFailure('The selected driver ID is invalid.'));
      return;
    }
    _isAutoAcceptingOffer = false;
    emit(BookingSearching(isDirect: true, targetDriver: targetDriver));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      emit(const BookingFailure('Passenger ID is missing.'));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = _pickupNameForTrip(event.trip);
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;

    try {
      final response = await _bookingDataSource.createSession({
        'ride_type': event.trip.rideType,
        'pickup_latitude': event.pickupLat,
        'pickup_longitude': event.pickupLng,
        'pickup_name': _pickupName,
        'dropoff_latitude': _dropoffLat,
        'dropoff_longitude': _dropoffLng,
        'dropoff_name': _dropoffName,
        'distance_km': event.distanceKm,
        'duration_minutes': event.durationMinutes,
        'target_driver_id': targetDriverId,
        'custom_fare_centavos': (event.trip.fare * 100).round(),
        'passenger_note': event.trip.passengerNote,
      });
      final sessionId = _sessionIdFromResponse(response);
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
    if (hasActiveBooking) return;
    emit(const BookingSearching(isDirect: false));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      emit(const BookingFailure('Passenger ID is missing.'));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = _pickupNameForTrip(event.trip);
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;

    try {
      final response = await _bookingDataSource.createSession({
        'ride_type': event.trip.rideType,
        'pickup_latitude': event.pickupLat,
        'pickup_longitude': event.pickupLng,
        'pickup_name': _pickupName,
        'dropoff_latitude': _dropoffLat,
        'dropoff_longitude': _dropoffLng,
        'dropoff_name': _dropoffName,
        'distance_km': event.distanceKm,
        'duration_minutes': event.durationMinutes,
        'custom_fare_centavos': (event.trip.fare * 100).round(),
        'passenger_note': event.trip.passengerNote,
      });
      final sessionId = _sessionIdFromResponse(response);
      if (sessionId == null || sessionId.isEmpty) {
        throw StateError('Booking session was not created');
      }
      _activeBidSessionId = sessionId;
      _subscribeToSession(sessionId);
    } catch (error) {
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
  }

  String _pickupNameForTrip(BidSessionTrip trip) {
    final pickupName = trip.pickupAddress?.trim();
    return pickupName == null || pickupName.isEmpty
        ? 'Current Location'
        : pickupName;
  }

  void _subscribeToSession(String sessionId) {
    _cleanupRealtimeSubscriptions();
    final realtimeClient = _realtimeClient;
    if (realtimeClient == null) {
      return;
    }
    _realtimeEventsSubscription = realtimeClient.events.listen((event) {
      if (event is! RideOfferUpdatedEvent || isClosed) {
        return;
      }
      final offer = event.envelope.payload['offer'];
      if (offer is! Map || offer['session_id']?.toString() != sessionId) {
        return;
      }
      final updatedOffer = Map<String, dynamic>.from(offer);
      final currentOffers = switch (state) {
        BookingOffersReceived(:final offers) => offers,
        _ => const <dynamic>[],
      };
      final updatedOffers =
          currentOffers
              .where((item) => item is! Map || item['id'] != updatedOffer['id'])
              .toList()
            ..add(updatedOffer);
      add(UpdateOffersEvent(updatedOffers));
    });
    _realtimeStateSubscription = realtimeClient.states.listen((state) {
      if (state is! RealtimeConnected) {
        return;
      }
      if (_realtimeWasConnected) {
        unawaited(_loadOfferSnapshot(sessionId));
      }
      _realtimeWasConnected = true;
    });
    unawaited(_connectAndLoadOfferSnapshot(sessionId));
  }

  Future<void> _connectAndLoadOfferSnapshot(String sessionId) async {
    final realtimeClient = _realtimeClient;
    if (realtimeClient == null) return;
    await realtimeClient.start();
    await _loadOfferSnapshot(sessionId);
  }

  Future<void> _loadOfferSnapshot(String sessionId) async {
    if (isClosed || _activeBidSessionId != sessionId) return;
    try {
      add(UpdateOffersEvent(await _bookingDataSource.fetchOffers(sessionId)));
    } catch (error) {
      dev.log('Failed to refresh booking offers: $error');
    }
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
      final offerId = pendingOffer['id']?.toString() ?? '';
      final proposedFareCentavos =
          (pendingOffer['proposed_fare_centavos'] as num?)?.toInt();
      final driverId = pendingOffer['driver_id']?.toString() ?? '';
      if (offerId.isNotEmpty &&
          driverId.isNotEmpty &&
          proposedFareCentavos != null &&
          proposedFareCentavos > 0) {
        _isAutoAcceptingOffer = true;
        add(
          AcceptBidOfferEvent(
            offerId: offerId,
            driverId: driverId,
            driverName: pendingOffer['driver_name']?.toString() ?? '',
            vehicleType: pendingOffer['vehicle_type']?.toString() ?? '',
            plateNumber: pendingOffer['plate_number']?.toString() ?? '',
            proposedFare: proposedFareCentavos / 100,
            driverRating: pendingOffer['driver_rating']?.toString(),
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

    emit(BookingDriverMatched(matchResult: event.matchResult));
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
      final response = await _bookingDataSource.acceptOffer(
        sessionId: sessionId,
        offerId: event.offerId,
      );
      final ride = response['ride'];
      final rideMap = ride is Map<String, dynamic>
          ? ride
          : const <String, dynamic>{};
      final rideId =
          response['ride_id']?.toString() ?? rideMap['id']?.toString() ?? '';
      if (rideId.isEmpty) {
        throw StateError('Accepted booking did not return a ride ID');
      }

      final pickupLat = _pickupLat;
      final pickupLng = _pickupLng;
      final dropoffLat = _dropoffLat;
      final dropoffLng = _dropoffLng;
      if (pickupLat == null ||
          pickupLng == null ||
          dropoffLat == null ||
          dropoffLng == null) {
        throw StateError('Booking coordinates are unavailable');
      }
      final fareCentavos =
          (rideMap['fare_centavos'] as num?)?.toDouble() ??
          event.proposedFare * 100;
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
            driverRating: event.driverRating,
          ),
          createdRide: RideHistoryModel(
            id: rideId,
            pickup: _pickupName ?? '',
            destination: _dropoffName ?? '',
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            destLat: dropoffLat,
            destLng: dropoffLng,
            date: DateTime.now().toLocal().toString(),
            price: '₱${(fareCentavos / 100).toStringAsFixed(2)}',
            status: RideStatus.accepted.value,
            driverId: event.driverId,
            driverName: event.driverName,
            vehiclePlate: event.plateNumber,
            vehicleType: event.vehicleType,
          ),
        ),
      );
      // Telemetry is supplementary to the accepted-ride transition. Keep it
      // off the critical path so the passenger sees the matched state as soon
      // as the authoritative ride has been persisted.
      unawaited(_startBackgroundTelemetry());
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
    await _stopBackgroundTelemetry();
    final sessionId = _activeBidSessionId;
    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        await _bookingDataSource
            .cancelSession(sessionId)
            .timeout(const Duration(seconds: 5));
      }
    } catch (error) {
      dev.log('Unable to confirm booking cancellation: $error');
    }
    emit(BookingCanceled());
    _activeBidSessionId = null;
  }

  void _onResetBooking(ResetBookingEvent event, Emitter<BookingState> emit) {
    _nearestSearchCancelled = true;
    _cleanupSubscriptions();
    _activeBidSessionId = null;
    _pickupLat = null;
    _pickupLng = null;
    _pickupName = null;
    _dropoffLat = null;
    _dropoffLng = null;
    _dropoffName = null;
    _totalTrips = null;
    _reviews = [];
    _isLoadingReviews = false;
    _isAutoAcceptingOffer = false;
    emit(BookingInitial());
  }

  void _cleanupSubscriptions() {
    _cleanupRealtimeSubscriptions();
  }

  void _cleanupRealtimeSubscriptions() {
    unawaited(_realtimeEventsSubscription?.cancel());
    unawaited(_realtimeStateSubscription?.cancel());
    _realtimeEventsSubscription = null;
    _realtimeStateSubscription = null;
    _realtimeWasConnected = false;
  }

  Future<void> _startBackgroundTelemetry() async {
    final service = _backgroundTelemetryService;
    if (service == null) return;
    try {
      await service.start();
    } catch (error) {
      dev.log('Unable to start passenger background telemetry: $error');
    }
  }

  Future<void> _stopBackgroundTelemetry() async {
    final service = _backgroundTelemetryService;
    if (service == null) return;
    try {
      await service.stop();
    } catch (error) {
      dev.log('Unable to stop passenger background telemetry: $error');
    }
  }

  @override
  Future<void> close() {
    _cleanupSubscriptions();
    unawaited(_stopBackgroundTelemetry());
    return super.close();
  }
}
