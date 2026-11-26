part of 'booking_bloc.dart';

extension _BookingBlocBidSession on BookingBloc {
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
      if (event.envelope.payload['session'] is Map) {
        unawaited(_loadOfferSnapshot(sessionId, source: 'session_event'));
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
    _realtimeStateSubscription = realtimeClient.states.listen((realtimeState) {
      if (isClosed || _activeBidSessionId != sessionId) return;
      if (realtimeState is RealtimeConnected) {
        if (_realtimeWasConnected) {
          unawaited(_loadOfferSnapshot(sessionId, source: 'reconnect'));
        }
        _realtimeWasConnected = true;
      } else if (realtimeState is RealtimeDisconnected) {
        unawaited(_loadOfferSnapshot(sessionId, source: 'realtime_fallback'));
      }
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
    var isInitialTick = true;
    final task = AppLifecyclePeriodicTask(
      lifecycleCoordinator: _lifecycleCoordinator,
      interval: _offerRefreshInterval,
      onTick: () {
        final source = isInitialTick ? 'initial' : 'periodic';
        isInitialTick = false;
        if (source == 'periodic' && _shouldSkipPeriodicHttpOfferPoll()) {
          return Future<void>.value();
        }
        return _loadOfferSnapshot(sessionId, source: source);
      },
      runImmediately: true,
    );
    _offerRefreshTask = task;
    task.start();
  }

  bool _shouldSkipPeriodicHttpOfferPoll() {
    if (_realtimeClient?.isConnected != true) return false;
    final expiresAt = switch (state) {
      BookingSearching(:final expiresAt) ||
      BookingOffersReceived(:final expiresAt) => expiresAt,
      _ => null,
    };
    if (expiresAt != null && !expiresAt.isAfter(_now())) {
      return false;
    }
    return true;
  }

  Future<void> _loadOfferSnapshot(
    String sessionId, {
    required String source,
  }) async {
    final flowGeneration = _bookingFlowGeneration;
    if (isClosed ||
        !_lifecycleCoordinator.isForeground ||
        _activeBidSessionId != sessionId ||
        _isCancellingBooking ||
        _isRefreshingOffers) {
      return;
    }
    _isRefreshingOffers = true;
    if (!kReleaseMode) {
      dev.Timeline.instantSync(
        'passenger.booking.offer_snapshot',
        arguments: {
          'source': source,
          'realtime_connected': _realtimeClient?.isConnected ?? false,
        },
      );
    }
    try {
      BidSessionSnapshot? sessionSnapshot;
      String? refreshError;
      final sessionResult = await _bookingRepository.fetchSessionResult(
        sessionId,
      );
      switch (sessionResult) {
        case Err(:final failure):
          refreshError = ErrorHandler.getErrorMessage(failure);
          dev.log('Failed to refresh booking session: ${failure.message}');
        case Ok(value: final session):
          if (session.id == sessionId) {
            sessionSnapshot = session;
          }
      }
      if (isClosed ||
          _activeBidSessionId != sessionId ||
          _isCancellingBooking ||
          flowGeneration != _bookingFlowGeneration) {
        return;
      }
      if (sessionSnapshot != null &&
          (sessionSnapshot.isAccepted ||
              sessionSnapshot.isCancelled ||
              sessionSnapshot.isDeclined ||
              sessionSnapshot.isExpired)) {
        add(UpdateOffersEvent(const [], session: sessionSnapshot));
        return;
      }

      List<BookingOffer>? offersSnapshot;
      final offersResult = await _bookingRepository.fetchOffersResult(
        sessionId,
      );
      switch (offersResult) {
        case Err(:final failure):
          refreshError ??= ErrorHandler.getErrorMessage(failure);
          dev.log('Failed to refresh booking offers: ${failure.message}');
        case Ok(value: final offers):
          offersSnapshot = offers;
      }
      if (!isClosed &&
          _lifecycleCoordinator.isForeground &&
          !_isCancellingBooking &&
          flowGeneration == _bookingFlowGeneration &&
          _activeBidSessionId == sessionId) {
        final previousOffers = switch (state) {
          BookingOffersReceived(:final offers) => offers,
          _ => const <BookingOffer>[],
        };
        add(
          UpdateOffersEvent(
            offersSnapshot ?? previousOffers,
            session: sessionSnapshot,
            refreshError: refreshError,
          ),
        );
      }
    } finally {
      _isRefreshingOffers = false;
    }
  }

  Future<void> _onUpdateOffers(
    UpdateOffersEvent event,
    Emitter<BookingState> emit,
  ) async {
    final flowGeneration = _bookingFlowGeneration;
    final session = event.session;
    if (session != null && session.isAccepted) {
      await _recoverAcceptedSession(session, emit);
      return;
    }
    if (_isCancellingBooking ||
        _cancelPendingBidSessionCreation ||
        _activeBidSessionId == null) {
      return;
    }
    if (session != null && session.isDeclined) {
      if (_activeBidSessionId != session.id) return;
      final selectedName = switch (state) {
        BookingSearching(:final targetDriver) ||
        BookingOffersReceived(
          :final targetDriver,
        ) => targetDriver?.displayName ?? 'The selected driver',
        _ => 'The selected driver',
      };
      _captureFailedDriverSearch();
      await _clearPendingBooking(session.id);
      if (isClosed || flowGeneration != _bookingFlowGeneration) return;
      emit(
        BookingFailure(
          '$selectedName declined your request. Choose another nearby driver.',
          isDriverDeclined: true,
        ),
      );
      return;
    }
    if (session != null && session.isCancelled) {
      if (_activeBidSessionId != session.id) return;
      _lastFailedDriverSearch = null;
      await _clearPendingBooking(session.id);
      if (isClosed || flowGeneration != _bookingFlowGeneration) return;
      emit(const BookingCanceled());
      return;
    }
    if (session != null && session.isExpired) {
      final sessionId = session.id;
      if (_activeBidSessionId != sessionId) return;
      try {
        await _secureSessionService.savePendingBidSessionCancellationId(
          sessionId,
        );
        if (isClosed || flowGeneration != _bookingFlowGeneration) return;
        await _cancelPersistedBookingSession(sessionId, emit, expired: true);
      } catch (error) {
        if (isClosed || flowGeneration != _bookingFlowGeneration) return;
        emit(
          BookingSessionRecoveryFailure(
            sessionId: sessionId,
            message: ErrorHandler.getErrorMessage(error),
          ),
        );
      }
      return;
    }

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
        await _onAcceptBidOffer(
          AcceptBidOfferEvent(
            offerId: pendingOffer.offerId,
            driverId: pendingOffer.driverId,
            driverName: driverName,
            vehicleType: vehicleType,
            plateNumber: plateNumber,
            proposedFare: pendingOffer.proposedFare,
            driverRating: pendingOffer.ratingLabel,
          ),
          emit,
        );
        return;
      }
    }

    final resolvedBookingReference =
        session != null && session.bookingReference.isNotEmpty
        ? session.bookingReference
        : null;
    switch (state) {
      case BookingSearching(
        :final isDirect,
        :final targetDriver,
        :final sessionId,
        :final bookingReference,
        :final expiresAt,
      ):
        emit(
          BookingOffersReceived(
            offers: event.offers,
            isDirect: isDirect,
            targetDriver: targetDriver,
            sessionId: sessionId,
            bookingReference: resolvedBookingReference ?? bookingReference,
            expiresAt: session?.expiresAt ?? expiresAt,
            refreshError: event.refreshError,
          ),
        );
      case BookingOffersReceived(
        :final isDirect,
        :final targetDriver,
        :final sessionId,
        :final bookingReference,
        :final expiresAt,
      ):
        emit(
          BookingOffersReceived(
            offers: event.offers,
            isDirect: isDirect,
            targetDriver: targetDriver,
            sessionId: sessionId,
            bookingReference: resolvedBookingReference ?? bookingReference,
            expiresAt: session?.expiresAt ?? expiresAt,
            refreshError: event.refreshError,
          ),
        );
      default:
        break;
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
    ++_bookingFlowGeneration;
    _nearestSearchCancelled = true;
    _cleanupSubscriptions();
    _activeTrip = null;
    _lastFailedDriverSearch = null;
    _activeBidSessionId = null;
    unawaited(_secureSessionService.deleteActiveBidSessionId());

    emit(BookingDriverMatched(matchResult: event.matchResult));
  }

  Future<void> _onAcceptBidOffer(
    AcceptBidOfferEvent event,
    Emitter<BookingState> emit,
  ) async {
    final sessionId = _activeBidSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _isAutoAcceptingOffer = false;
      emit(const BookingFailure('Booking session is no longer available.'));
      return;
    }

    try {
      final acceptResult = await _bookingRepository.acceptOfferResult(
        sessionId: sessionId,
        offerId: event.offerId,
      );
      final AcceptedBooking acceptedBooking;
      switch (acceptResult) {
        case Err(:final failure):
          throw failure;
        case Ok(:final value):
          acceptedBooking = value;
      }
      final rideId = acceptedBooking.typedRideId.normalized;
      await _secureSessionService.saveActiveRideId(rideId);
      await _secureSessionService.deleteActiveBidSessionId();
      await _secureSessionService.deletePendingBidSessionCreation();
      await _secureSessionService.deletePendingBidSessionCancellationId();
      _activeBidSessionId = null;
      _isAutoAcceptingOffer = false;
      _cleanupSubscriptions();
      _activeTrip = null;
      _lastFailedDriverSearch = null;
      _distanceKm = null;
      _durationMinutes = null;
      if (isClosed) return;
      final fareAmount = acceptedBooking.fareAmount;
      final confirmedFare = (fareAmount != null && fareAmount > 0)
          ? fareAmount / 100
          : event.proposedFare;
      emit(
        BookingDriverMatched(
          matchResult: DriverMatchResult(
            driverId: event.driverId,
            driverName: event.driverName,
            vehicleType: event.vehicleType,
            plateNumber: event.plateNumber,
            proposedFare: confirmedFare,
            driverRating: event.driverRating,
          ),
          rideId: rideId,
        ),
      );
      // Telemetry is supplementary to the accepted-ride transition. Keep it
      // off the critical path so the passenger sees the matched state as soon
      // as the authoritative ride has been persisted.
      unawaited(_startBackgroundTelemetry());
    } catch (error) {
      _isAutoAcceptingOffer = false;
      _cleanupSubscriptions();
      if (isClosed) return;
      emit(
        BookingSessionRecoveryFailure(
          sessionId: sessionId,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    _stopNearbyDriverSearch();
    ++_bookingFlowGeneration;
    _nearestSearchCancelled = true;
    if (_isCreatingBidSession) {
      _cancelPendingBidSessionCreation = true;
      try {
        await _secureSessionService.requestPendingBidSessionCancellation();
        final sessionId = _activeBidSessionId;
        if (sessionId != null && sessionId.isNotEmpty) {
          await _secureSessionService.savePendingBidSessionCancellationId(
            sessionId,
          );
        }
        if (isClosed) return;
        emit(BookingSessionRecoveryInProgress(sessionId: sessionId ?? ''));
      } catch (error) {
        if (isClosed) return;
        emit(
          BookingSessionRecoveryFailure(
            sessionId: '',
            message: ErrorHandler.getErrorMessage(error),
          ),
        );
      }
      return;
    }

    final sessionId = _activeBidSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      PendingBidSessionCreation? pendingCreation;
      try {
        pendingCreation = await _secureSessionService
            .readPendingBidSessionCreation();
        if (pendingCreation != null) {
          _cancelPendingBidSessionCreation = true;
          await _secureSessionService.requestPendingBidSessionCancellation();
          if (isClosed) return;
          emit(const BookingSessionRecoveryInProgress(sessionId: ''));
          await _createOrRecoverPendingSession(newRequest: null, emit: emit);
          return;
        }
      } catch (error) {
        if (isClosed) return;
        emit(
          BookingSessionRecoveryFailure(
            sessionId: '',
            message: ErrorHandler.getErrorMessage(error),
          ),
        );
        return;
      }
      _cleanupSubscriptions();
      await _stopBackgroundTelemetry();
      _activeTrip = null;
      _lastFailedDriverSearch = null;
      _pickupLat = null;
      _pickupLng = null;
      _distanceKm = null;
      _durationMinutes = null;
      if (isClosed) return;
      emit(const BookingCanceled());
      return;
    }

    try {
      await _secureSessionService.savePendingBidSessionCancellationId(
        sessionId,
      );
      await _cancelPersistedBookingSession(sessionId, emit);
    } catch (error) {
      dev.log('Unable to persist booking cancellation: $error');
      if (isClosed) return;
      emit(
        BookingSessionRecoveryFailure(
          sessionId: sessionId,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _onResetBooking(
    ResetBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (_isCreatingBidSession) return;
    final activeSessionId = _activeBidSessionId;
    if (activeSessionId != null &&
        state is! BookingFailure &&
        state is! BookingCanceled) {
      return;
    }
    final generation = ++_bookingFlowGeneration;
    if (activeSessionId != null) {
      await _clearPendingBooking(activeSessionId);
      if (isClosed || generation != _bookingFlowGeneration) return;
    }
    _nearestSearchCancelled = true;
    _cleanupSubscriptions();
    _activeTrip = null;
    _lastFailedDriverSearch = null;
    _pickupLat = null;
    _pickupLng = null;
    _pickupName = null;
    _distanceKm = null;
    _durationMinutes = null;
    _totalTrips = null;
    ++_reviewsRequestGeneration;
    _isAutoAcceptingOffer = false;
    await _secureSessionService.deletePendingBidSessionCreation();
    await _secureSessionService.deletePendingBidSessionCancellationId();
    if (isClosed || generation != _bookingFlowGeneration) return;
    emit(const BookingInitial());
  }

  void _cleanupSubscriptions() {
    _stopNearbyDriverSearch();
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
}
