import 'package:passenger_app/src/features/active_ride/active_ride.dart';
import 'package:passenger_app/src/features/activity/activity.dart';
import 'package:passenger_app/src/features/booking/booking.dart';
import 'package:passenger_app/src/features/auth/domain/failures/auth_failures.dart';
import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/infrastructure/telemetry/passenger_background_telemetry.dart';
import 'package:passenger_app/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger_app/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/active_ride/domain/entities/accepted_booking.dart';
import 'package:passenger_app/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:passenger_app/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger_app/src/features/booking/domain/entities/booking_session_request.dart';
import 'package:passenger_app/src/features/booking/domain/repositories/booking_repository.dart';
import 'package:passenger_app/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:foundation/foundation.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final DriverRepository _driverRepository;
  final BookingRepository _bookingRepository;
  final DriverProfileRepository _driverProfileRepository;
  final PassengerSessionStore _secureSessionService;
  final PassengerBackgroundTelemetry? _backgroundTelemetryService;
  final InboxCubit? _inboxCubit;
  final RealtimeWebSocketClient? _realtimeClient;
  final AppLifecycleCoordinator _lifecycleCoordinator;
  final int _nearestDriverMaxAttempts;
  final Duration _nearestDriverRetryDelay;
  final Duration _offerRefreshInterval;

  StreamSubscription<RealtimeEvent>? _realtimeEventsSubscription;
  StreamSubscription<RealtimeConnectionState>? _realtimeStateSubscription;
  AppLifecyclePeriodicTask? _offerRefreshTask;

  int? _totalTrips;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = false;
  bool _nearestSearchCancelled = false;
  bool _noDriverNotificationSent = false;
  bool _isAutoAcceptingOffer = false;
  bool _isRefreshingOffers = false;
  bool _realtimeWasConnected = false;
  String? _activeBidSessionId;

  double? _pickupLat;
  double? _pickupLng;
  String? _pickupName;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _dropoffName;

  BookingBloc({
    required DriverRepository driverRepository,
    required BookingRepository bookingRepository,
    required DriverProfileRepository driverProfileRepository,
    required PassengerSessionStore secureSessionService,
    InboxCubit? inboxCubit,
    PassengerBackgroundTelemetry? backgroundTelemetryService,
    RealtimeWebSocketClient? realtimeClient,
    required AppLifecycleCoordinator lifecycleCoordinator,
    int nearestDriverMaxAttempts = 5,
    Duration nearestDriverRetryDelay = const Duration(seconds: 2),
    Duration offerRefreshInterval = const Duration(seconds: 3),
  }) : assert(nearestDriverMaxAttempts > 0),
       assert(offerRefreshInterval > Duration.zero),
       _driverRepository = driverRepository,
       _bookingRepository = bookingRepository,
       _driverProfileRepository = driverProfileRepository,
       _secureSessionService = secureSessionService,
       _inboxCubit = inboxCubit,
       _backgroundTelemetryService = backgroundTelemetryService,
       _realtimeClient = realtimeClient,
       _lifecycleCoordinator = lifecycleCoordinator,
       _nearestDriverMaxAttempts = nearestDriverMaxAttempts,
       _nearestDriverRetryDelay = nearestDriverRetryDelay,
       _offerRefreshInterval = offerRefreshInterval,
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
              ? ErrorHandler.getErrorMessage(const NoDriversAvailableFailure())
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
    int? totalTrips;
    (await _driverProfileRepository.fetchStats(driverId)).fold(
      (failure) => dev.log('Unable to load driver stats: ${failure.message}'),
      (stats) => totalTrips = stats.completedTrips,
    );
    return totalTrips;
  }

  Future<List<Map<String, dynamic>>> _loadDriverReviews(String driverId) async {
    List<Map<String, dynamic>> reviews = const [];
    (await _driverProfileRepository.fetchReviews(driverId)).fold(
      (failure) => dev.log('Failed to process reviews: ${failure.message}'),
      (values) => reviews = values
          .map(
            (review) => <String, dynamic>{
              'passengerName': review.passengerName,
              'comment': review.comment,
              'rating': review.rating,
              'date': review.displayDate,
            },
          )
          .toList(growable: false),
    );
    return reviews;
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
      emit(
        BookingFailure(ErrorHandler.getErrorMessage(const ValidationFailure())),
      );
      return;
    }
    _isAutoAcceptingOffer = false;
    emit(BookingSearching(isDirect: true, targetDriver: targetDriver));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      emit(BookingFailure(ErrorHandler.getErrorMessage(const AuthFailure())));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = _pickupNameForTrip(event.trip);
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;

    try {
      String? sessionId;
      Failure? failure;
      (await _bookingRepository.createSession(
        _bookingRequest(
          trip: event.trip,
          pickupLat: event.pickupLat,
          pickupLng: event.pickupLng,
          distanceKm: event.distanceKm,
          durationMinutes: event.durationMinutes,
          targetDriverId: targetDriverId,
        ),
      )).fold((value) => failure = value, (value) => sessionId = value);
      if (sessionId == null) throw failure!;
      _activeBidSessionId = sessionId;
      _subscribeToSession(sessionId!);
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
      emit(BookingFailure(ErrorHandler.getErrorMessage(const AuthFailure())));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = _pickupNameForTrip(event.trip);
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;

    try {
      String? sessionId;
      Failure? failure;
      (await _bookingRepository.createSession(
        _bookingRequest(
          trip: event.trip,
          pickupLat: event.pickupLat,
          pickupLng: event.pickupLng,
          distanceKm: event.distanceKm,
          durationMinutes: event.durationMinutes,
        ),
      )).fold((value) => failure = value, (value) => sessionId = value);
      if (sessionId == null) throw failure!;
      _activeBidSessionId = sessionId;
      _subscribeToSession(sessionId!);
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

  BookingSessionRequest _bookingRequest({
    required BidSessionTrip trip,
    required double pickupLat,
    required double pickupLng,
    required double distanceKm,
    required double durationMinutes,
    int? targetDriverId,
  }) {
    return BookingSessionRequest(
      rideType: trip.rideType,
      pickupLatitude: pickupLat,
      pickupLongitude: pickupLng,
      pickupName: _pickupName ?? _pickupNameForTrip(trip),
      dropoffLatitude: trip.destination.latitude,
      dropoffLongitude: trip.destination.longitude,
      dropoffName: trip.destination.name,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      targetDriverId: targetDriverId,
      customFareCentavos: (trip.fare * 100).round(),
      passengerNote: trip.passengerNote,
    );
  }

  void _subscribeToSession(String sessionId) {
    _cleanupRealtimeSubscriptions();
    _startOfferRefresh(sessionId);
    final realtimeClient = _realtimeClient;
    if (realtimeClient == null) {
      return;
    }
    _realtimeEventsSubscription = realtimeClient.events.listen((event) {
      if (event is! RideOfferUpdatedEvent || isClosed) {
        return;
      }
      final offer = event.envelope.payload['offer'];
      if (offer is! Map) {
        return;
      }
      final updatedOffer = BookingOffer.tryParse(
        Map<String, dynamic>.from(offer),
      );
      if (updatedOffer == null || updatedOffer.sessionId != sessionId) return;
      final currentOffers = switch (state) {
        BookingOffersReceived(:final offers) => offers,
        _ => const <BookingOffer>[],
      };
      final updatedOffers =
          currentOffers
              .where((item) => item.offerId != updatedOffer.offerId)
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
    unawaited(_connectRealtime());
  }

  Future<void> _connectRealtime() async {
    final realtimeClient = _realtimeClient;
    if (realtimeClient == null || !_lifecycleCoordinator.isForeground) return;
    try {
      await realtimeClient.start();
    } catch (error) {
      dev.log('Realtime booking updates are unavailable: $error');
    }
  }

  void _startOfferRefresh(String sessionId) {
    unawaited(_offerRefreshTask?.dispose());
    final task = AppLifecyclePeriodicTask(
      lifecycleCoordinator: _lifecycleCoordinator,
      interval: _offerRefreshInterval,
      onTick: () => _loadOfferSnapshot(sessionId),
      runImmediately: true,
    );
    _offerRefreshTask = task;
    task.start();
  }

  Future<void> _loadOfferSnapshot(String sessionId) async {
    if (isClosed ||
        !_lifecycleCoordinator.isForeground ||
        _activeBidSessionId != sessionId ||
        _isRefreshingOffers) {
      return;
    }
    _isRefreshingOffers = true;
    try {
      (await _bookingRepository.fetchOffers(sessionId)).fold(
        (failure) =>
            dev.log('Failed to refresh booking offers: ${failure.message}'),
        (offers) {
          if (!isClosed &&
              _lifecycleCoordinator.isForeground &&
              _activeBidSessionId == sessionId) {
            add(UpdateOffersEvent(offers));
          }
        },
      );
    } finally {
      _isRefreshingOffers = false;
    }
  }

  void _onUpdateOffers(UpdateOffersEvent event, Emitter<BookingState> emit) {
    final isDirectBooking = switch (state) {
      BookingSearching(:final isDirect) => isDirect,
      BookingOffersReceived(:final isDirect) => isDirect,
      _ => false,
    };

    if (isDirectBooking && event.offers.isNotEmpty && !_isAutoAcceptingOffer) {
      BookingOffer? pendingOffer;
      for (final offer in event.offers) {
        if (offer.status == 'pending') {
          pendingOffer = offer;
          break;
        }
      }
      if (pendingOffer != null) {
        final targetDriver = switch (state) {
          BookingSearching(:final targetDriver) => targetDriver,
          BookingOffersReceived(:final targetDriver) => targetDriver,
          _ => null,
        };
        final driverName = _preferDisplayValue(
          pendingOffer.driverName,
          targetDriver?.name,
          pendingOffer.displayDriverName,
        );
        final vehicleType = _preferDisplayValue(
          pendingOffer.vehicleType,
          targetDriver?.vehicleType,
          pendingOffer.displayVehicleType,
        );
        final plateNumber = _preferDisplayValue(
          pendingOffer.plateNumber,
          targetDriver?.plateNumber,
          pendingOffer.displayPlateNumber,
        );
        _isAutoAcceptingOffer = true;
        add(
          AcceptBidOfferEvent(
            offerId: pendingOffer.offerId,
            driverId: pendingOffer.driverId,
            driverName: driverName,
            vehicleType: vehicleType,
            plateNumber: plateNumber,
            proposedFare: pendingOffer.proposedFare,
            driverRating: pendingOffer.ratingLabel,
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

  String _preferDisplayValue(
    String primary,
    String? fallback,
    String placeholder,
  ) {
    final primaryValue = primary.trim();
    if (primaryValue.isNotEmpty) return primaryValue;
    final fallbackValue = fallback?.trim() ?? '';
    return fallbackValue.isNotEmpty ? fallbackValue : placeholder;
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
      AcceptedBooking? acceptedBooking;
      Failure? failure;
      (await _bookingRepository.acceptOffer(
        sessionId: sessionId,
        offerId: event.offerId,
      )).fold((value) => failure = value, (value) => acceptedBooking = value);
      if (acceptedBooking == null) throw failure!;
      final rideId = acceptedBooking!.rideId;

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
          acceptedBooking!.fareCentavos ?? (event.proposedFare * 100).round();
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
          createdRide: RideHistory(
            id: rideId,
            pickup: _pickupName ?? '',
            destination: _dropoffName ?? '',
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            destLat: dropoffLat,
            destLng: dropoffLng,
            date: DateTime.now().toLocal().toString(),
            price: formatPesoAmount(fareCentavos / 100),
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
      _cleanupSubscriptions();
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
        await _bookingRepository
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
    unawaited(_offerRefreshTask?.dispose());
    _offerRefreshTask = null;
    _isRefreshingOffers = false;
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
