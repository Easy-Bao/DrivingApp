import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/telemetry/background_telemetry.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_session_request.dart';
import 'package:passenger/src/features/booking/domain/repositories/booking_repository.dart';
import 'package:passenger/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

part 'booking_event.dart';
part 'booking_state.dart';
part 'booking_bloc_driver_discovery.dart';
part 'booking_bloc_session_creation.dart';
part 'booking_bloc_bid_session.dart';
part 'booking_bloc_session_recovery.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  static const Duration defaultNearbyDriverSearchTimeout = Duration(
    seconds: 15,
  );
  static const Duration defaultNearbyDriverEmptyPollInterval = Duration(
    seconds: 3,
  );
  static const Duration defaultNearbyDriverActivePollInterval = Duration(
    seconds: 10,
  );

  final DriverRepository _driverRepository;
  final BookingRepository _bookingRepository;
  final DriverProfileRepository _driverProfileRepository;
  final SessionStore _secureSessionService;
  final BackgroundTelemetry? _backgroundTelemetryService;
  final RealtimeWebSocketClient? _realtimeClient;
  final AppLifecycleCoordinator _lifecycleCoordinator;
  final int _nearestDriverMaxAttempts;
  final Duration _nearestDriverRetryDelay;
  final Duration _offerRefreshInterval;
  final Duration _nearbyDriverSearchTimeout;
  final Duration _nearbyDriverEmptyPollInterval;
  final Duration _nearbyDriverActivePollInterval;
  final DateTime Function() _now;

  StreamSubscription<RealtimeEvent>? _realtimeEventsSubscription;
  StreamSubscription<RealtimeConnectionState>? _realtimeStateSubscription;
  AppLifecyclePeriodicTask? _offerRefreshTask;
  Timer? _nearbyDriverPollTimer;
  Timer? _nearbyDriverTimeoutTimer;
  StreamSubscription<AppLifecycleStatus>? _nearbyDriverLifecycleSubscription;

  int? _totalTrips;
  int _reviewsRequestGeneration = 0;
  int _nearbySearchGeneration = 0;
  int _bookingFlowGeneration = 0;
  bool _nearestSearchCancelled = false;
  bool _isAutoAcceptingOffer = false;
  bool _isCreatingBidSession = false;
  bool _isCancellingBooking = false;
  bool _cancelPendingBidSessionCreation = false;
  bool _isRefreshingOffers = false;
  bool _isFetchingNearbyDrivers = false;
  bool _nearbySearchTimedOutWaitingForLookup = false;
  bool _realtimeWasConnected = false;
  Duration _nearbySearchRemainingTimeout = Duration.zero;
  DateTime? _nearbySearchTimerStartedAt;
  final Random _idempotencyRandom = Random.secure();
  String? _activeBidSessionId;
  BidSessionTrip? _activeTrip;
  ActiveDriverSearch? _lastFailedDriverSearch;

  double? _pickupLat;
  double? _pickupLng;
  String? _pickupName;
  double? _distanceKm;
  double? _durationMinutes;

  BookingBloc({
    required this._driverRepository,
    required this._bookingRepository,
    required this._driverProfileRepository,
    required this._secureSessionService,
    this._backgroundTelemetryService,
    this._realtimeClient,
    required this._lifecycleCoordinator,
    int nearestDriverMaxAttempts = 5,
    this._nearestDriverRetryDelay = const Duration(seconds: 3),
    Duration offerRefreshInterval = const Duration(seconds: 3),
    Duration nearbyDriverSearchTimeout = defaultNearbyDriverSearchTimeout,
    Duration nearbyDriverEmptyPollInterval =
        defaultNearbyDriverEmptyPollInterval,
    Duration nearbyDriverActivePollInterval =
        defaultNearbyDriverActivePollInterval,
    DateTime Function()? now,
  }) : assert(nearestDriverMaxAttempts > 0),
       assert(offerRefreshInterval > Duration.zero),
       assert(nearbyDriverSearchTimeout > Duration.zero),
       assert(nearbyDriverEmptyPollInterval > Duration.zero),
       assert(nearbyDriverActivePollInterval > Duration.zero),
       _nearestDriverMaxAttempts = nearestDriverMaxAttempts,
       _offerRefreshInterval = offerRefreshInterval,
       _nearbyDriverSearchTimeout = nearbyDriverSearchTimeout,
       _nearbyDriverEmptyPollInterval = nearbyDriverEmptyPollInterval,
       _nearbyDriverActivePollInterval = nearbyDriverActivePollInterval,
       _now = now ?? DateTime.now,
       super(const BookingInitial()) {
    on<LocateNearestDriverEvent>(
      _onLocateNearestDriver,
      transformer: droppable(),
    );
    on<StartNearbyDriverSearchEvent>(_onStartNearbyDriverSearch);
    on<_NearbyDriversPollCompletedEvent>(_onNearbyDriversPollCompleted);
    on<_NearbyDriverSearchTimedOutEvent>(_onNearbyDriverSearchTimedOut);
    on<LoadDriverReviewsEvent>(
      _onLoadDriverReviews,
      transformer: restartable(),
    );
    on<StartDirectBookingEvent>(
      _onStartDirectBooking,
      transformer: droppable(),
    );
    on<StartOpenBookingEvent>(_onStartOpenBooking, transformer: droppable());
    on<AcceptBidOfferEvent>(_onAcceptBidOffer, transformer: droppable());
    on<CancelBookingEvent>(_onCancelBooking, transformer: droppable());
    on<ResetBookingEvent>(_onResetBooking);
    on<RestoreActiveBookingEvent>(
      _onRestoreActiveBooking,
      transformer: droppable(),
    );
    on<RefreshBookingSessionEvent>((_, _) {
      final sessionId = _activeBidSessionId;
      if (sessionId != null) {
        unawaited(_loadOfferSnapshot(sessionId, source: 'manual'));
        return;
      }
      if (state is BookingFindingNearbyDrivers) {
        unawaited(_pollNearbyDrivers(generation: _nearbySearchGeneration));
      }
    });
    on<UpdateOffersEvent>(_onUpdateOffers);
    on<DriverMatchedEvent>(_onDriverMatched);
  }

  String? get activeBidSessionId => _activeBidSessionId;

  bool get hasActiveDriverSearch =>
      state is FindingNearestDriver ||
      state is BookingFindingNearbyDrivers ||
      state is NearestDriverFound ||
      state is BookingSearching ||
      state is BookingOffersReceived ||
      state is BookingSessionRecoveryInProgress ||
      state is BookingSessionRecoveryFailure ||
      _activeBidSessionId != null;

  ActiveDriverSearch? get activeDriverSearch {
    final trip = _activeTrip;
    final pickupLat = _pickupLat;
    final pickupLng = _pickupLng;
    final isExpiredRequest = switch (state) {
      BookingFailure(:final isRequestExpired) => isRequestExpired,
      _ => false,
    };
    if ((!hasActiveDriverSearch && !isExpiredRequest) ||
        trip == null ||
        pickupLat == null ||
        pickupLng == null) {
      return null;
    }
    return ActiveDriverSearch(
      trip: trip,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      distanceKm: _distanceKm,
      durationMinutes: _durationMinutes,
    );
  }

  ActiveDriverSearch? get retryableDriverSearch {
    if (!state.isNoDriverOrTimedOutFailure) return null;
    return _lastFailedDriverSearch;
  }

  bool get hasActiveBooking =>
      state is BookingSearching ||
      state is BookingOffersReceived ||
      state is BookingDriverMatched ||
      state is BookingRideRecovered ||
      state is BookingSessionRecoveryInProgress ||
      state is BookingSessionRecoveryFailure;

  void _captureFailedDriverSearch() {
    final trip = _activeTrip;
    final pickupLat = _pickupLat;
    final pickupLng = _pickupLng;
    if (trip == null || pickupLat == null || pickupLng == null) return;
    _lastFailedDriverSearch = ActiveDriverSearch(
      trip: trip,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      distanceKm: _distanceKm,
      durationMinutes: _durationMinutes,
    );
  }

  String _pickupNameForTrip(BidSessionTrip trip) {
    final pickupName = trip.pickupAddress?.trim();
    return pickupName == null || pickupName.isEmpty
        ? 'Current Location'
        : pickupName;
  }

  @override
  Future<void> close() async {
    _cleanupSubscriptions();
    await _nearbyDriverLifecycleSubscription?.cancel();
    _nearbyDriverLifecycleSubscription = null;
    await _realtimeEventsSubscription?.cancel();
    _realtimeEventsSubscription = null;
    await _realtimeStateSubscription?.cancel();
    _realtimeStateSubscription = null;
    await _stopBackgroundTelemetry();
    return super.close();
  }
}
