import 'dart:async';
import 'dart:developer' as dev;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/domain/entities/accepted_booking.dart';
import 'package:passenger/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_session_request.dart';
import 'package:passenger/src/features/booking/domain/repositories/booking_repository.dart';
import 'package:passenger/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger/src/infrastructure/telemetry/passenger_background_telemetry.dart';

part 'booking_event.dart';
part 'booking_state.dart';
part 'booking_bloc_driver_discovery.dart';
part 'booking_bloc_session_creation.dart';
part 'booking_bloc_bid_session.dart';

class BookingBloc({
  required this._driverRepository,
  required this._bookingRepository,
  required this._driverProfileRepository,
  required this._secureSessionService,
  this._inboxCubit,
  this._backgroundTelemetryService,
  this._realtimeClient,
  required this._lifecycleCoordinator,
  int nearestDriverMaxAttempts = 1,
  this._nearestDriverRetryDelay = const Duration(seconds: 2),
  Duration offerRefreshInterval = const Duration(seconds: 3),
}) extends Bloc<BookingEvent, BookingState> {
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
  int _reviewsRequestGeneration = 0;
  bool _nearestSearchCancelled = false;
  bool _noDriverNotificationSent = false;
  bool _isAutoAcceptingOffer = false;
  bool _isRefreshingOffers = false;
  bool _realtimeWasConnected = false;
  String? _activeBidSessionId;
  BidSessionTrip? _activeTrip;

  double? _pickupLat;
  double? _pickupLng;
  String? _pickupName;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _dropoffName;

  this
    : assert(nearestDriverMaxAttempts > 0),
      assert(offerRefreshInterval > Duration.zero),
      _nearestDriverMaxAttempts = nearestDriverMaxAttempts,
      _offerRefreshInterval = offerRefreshInterval,
      super(const BookingInitial()) {
    on<LocateNearestDriverEvent>(
      this._onLocateNearestDriver,
      transformer: droppable(),
    );
    on<LoadDriverReviewsEvent>(
      this._onLoadDriverReviews,
      transformer: restartable(),
    );
    on<StartDirectBookingEvent>(
      this._onStartDirectBooking,
      transformer: droppable(),
    );
    on<StartOpenBookingEvent>(
      this._onStartOpenBooking,
      transformer: droppable(),
    );
    on<AcceptBidOfferEvent>(this._onAcceptBidOffer, transformer: droppable());
    on<CancelBookingEvent>(this._onCancelBooking, transformer: droppable());
    on<ResetBookingEvent>(this._onResetBooking);
    on<UpdateOffersEvent>(this._onUpdateOffers);
    on<DriverMatchedEvent>(this._onDriverMatched);
  }

  bool get hasActiveDriverSearch =>
      state is FindingNearestDriver ||
      state is NearestDriverFound ||
      state is BookingSearching ||
      state is BookingOffersReceived;

  ActiveDriverSearch? get activeDriverSearch {
    final trip = _activeTrip;
    final pickupLat = _pickupLat;
    final pickupLng = _pickupLng;
    if (!hasActiveDriverSearch ||
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
      state is BookingDriverMatched;

  String _pickupNameForTrip(BidSessionTrip trip) {
    final pickupName = trip.pickupAddress?.trim();
    return pickupName == null || pickupName.isEmpty
        ? 'Current Location'
        : pickupName;
  }

  @override
  Future<void> close() {
    this._cleanupSubscriptions();
    unawaited(this._stopBackgroundTelemetry());
    return super.close();
  }
}
