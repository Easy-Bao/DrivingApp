import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/telemetry/background_telemetry.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
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

  StreamSubscription<RealtimeEvent>? _realtimeEventsSubscription;
  StreamSubscription<RealtimeConnectionState>? _realtimeStateSubscription;
  AppLifecyclePeriodicTask? _offerRefreshTask;

  int? _totalTrips;
  int _reviewsRequestGeneration = 0;
  bool _nearestSearchCancelled = false;
  bool _isAutoAcceptingOffer = false;
  bool _isCreatingBidSession = false;
  bool _cancelPendingBidSessionCreation = false;
  bool _isRefreshingOffers = false;
  bool _realtimeWasConnected = false;
  final Random _idempotencyRandom = Random.secure();
  String? _activeBidSessionId;
  BidSessionTrip? _activeTrip;

  double? _pickupLat;
  double? _pickupLng;
  String? _pickupName;
  double? _dropoffLat;
  double? _dropoffLng;

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
  }) : assert(nearestDriverMaxAttempts > 0),
       assert(offerRefreshInterval > Duration.zero),
       _nearestDriverMaxAttempts = nearestDriverMaxAttempts,
       _offerRefreshInterval = offerRefreshInterval,
       super(const BookingInitial()) {
    on<LocateNearestDriverEvent>(
      _onLocateNearestDriver,
      transformer: droppable(),
    );
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
      }
    });
    on<UpdateOffersEvent>(_onUpdateOffers);
    on<DriverMatchedEvent>(_onDriverMatched);
  }

  String? get activeBidSessionId => _activeBidSessionId;

  bool get hasActiveDriverSearch =>
      state is FindingNearestDriver ||
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
    final isExpiredRequest =
        state is BookingFailure && (state as BookingFailure).isRequestExpired;
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
    );
  }

  bool get hasActiveBooking =>
      state is BookingSearching ||
      state is BookingOffersReceived ||
      state is BookingDriverMatched ||
      state is BookingSessionRecoveryInProgress ||
      state is BookingSessionRecoveryFailure;

  String _pickupNameForTrip(BidSessionTrip trip) {
    final pickupName = trip.pickupAddress?.trim();
    return pickupName == null || pickupName.isEmpty
        ? 'Current Location'
        : pickupName;
  }

  @override
  Future<void> close() async {
    _cleanupSubscriptions();
    await _realtimeEventsSubscription?.cancel();
    _realtimeEventsSubscription = null;
    await _realtimeStateSubscription?.cancel();
    _realtimeStateSubscription = null;
    await _stopBackgroundTelemetry();
    return super.close();
  }
}
