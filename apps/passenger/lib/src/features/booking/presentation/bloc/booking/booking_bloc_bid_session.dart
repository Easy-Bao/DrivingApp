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
        unawaited(_loadOfferSnapshot(sessionId, source: 'reconnect'));
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
      onTick: () => _loadOfferSnapshot(sessionId, source: 'periodic'),
      runImmediately: true,
    );
    _offerRefreshTask = task;
    task.start();
  }

  Future<void> _loadOfferSnapshot(
    String sessionId, {
    required String source,
  }) async {
    if (isClosed ||
        !_lifecycleCoordinator.isForeground ||
        _activeBidSessionId != sessionId ||
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
      DateTime? expiresAt;
      String? sessionStatus;
      BidSessionSnapshot? sessionSnapshot;
      String? refreshError;
      (await _bookingRepository.fetchSessionResult(sessionId)).fold(
        (failure) {
          refreshError = ErrorHandler.getErrorMessage(failure);
          dev.log('Failed to refresh booking session: ${failure.message}');
        },
        (session) {
          if (session.id == sessionId) {
            sessionSnapshot = session;
            expiresAt = session.expiresAt;
            sessionStatus = session.status;
          }
        },
      );
      if (_activeBidSessionId != sessionId || isClosed) return;
      if (sessionSnapshot?.isAccepted == true ||
          sessionSnapshot?.isCancelled == true) {
        add(UpdateOffersEvent(const [], session: sessionSnapshot));
        return;
      }
      if (sessionSnapshot?.isExpired == true) {
        add(UpdateOffersEvent(const [], session: sessionSnapshot));
        return;
      }

      List<BookingOffer>? offersSnapshot;
      (await _bookingRepository.fetchOffersResult(sessionId)).fold((failure) {
        refreshError ??= ErrorHandler.getErrorMessage(failure);
        dev.log('Failed to refresh booking offers: ${failure.message}');
      }, (offers) => offersSnapshot = offers);
      if (!isClosed &&
          _lifecycleCoordinator.isForeground &&
          _activeBidSessionId == sessionId) {
        final previousOffers = switch (state) {
          BookingOffersReceived(:final offers) => offers,
          _ => const <BookingOffer>[],
        };
        add(
          UpdateOffersEvent(
            offersSnapshot ?? previousOffers,
            session:
                sessionSnapshot ??
                (sessionStatus == null
                    ? null
                    : BidSessionSnapshot(
                        id: sessionId,
                        status: sessionStatus!,
                        expiresAt: expiresAt,
                      )),
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
    final session = event.session;
    if (session?.isAccepted == true) {
      await _recoverAcceptedSession(session!, emit);
      return;
    }
    if (session?.isCancelled == true) {
      await _clearPendingBooking(session!.id);
      emit(const BookingCanceled());
      return;
    }
    if (session?.isExpired == true) {
      await _clearPendingBooking(session!.id);
      emit(
        BookingFailure(
          'This request expired before a driver accepted it.',
          isRequestExpired: true,
          sessionId: session.id,
        ),
      );
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

    if (state is BookingSearching) {
      final current = state as BookingSearching;
      emit(
        BookingOffersReceived(
          offers: event.offers,
          isDirect: current.isDirect,
          targetDriver: current.targetDriver,
          sessionId: current.sessionId,
          expiresAt: session?.expiresAt ?? current.expiresAt,
          refreshError: event.refreshError,
        ),
      );
    } else if (state is BookingOffersReceived) {
      final current = state as BookingOffersReceived;
      emit(
        BookingOffersReceived(
          offers: event.offers,
          isDirect: current.isDirect,
          targetDriver: current.targetDriver,
          sessionId: current.sessionId,
          expiresAt: session?.expiresAt ?? current.expiresAt,
          refreshError: event.refreshError,
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
    _activeTrip = null;
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
      emit(const BookingFailure('Booking session is no longer available.'));
      return;
    }

    try {
      AcceptedBooking? acceptedBooking;
      Failure? failure;
      (await _bookingRepository.acceptOfferResult(
        sessionId: sessionId,
        offerId: event.offerId,
      )).fold((value) => failure = value, (value) => acceptedBooking = value);
      if (acceptedBooking == null) throw failure!;
      final rideId = acceptedBooking!.typedRideId.normalized;

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
      await _secureSessionService.saveActiveRideId(rideId);
      await _secureSessionService.deleteActiveBidSessionId();
      await _secureSessionService.deletePendingBidSessionCreation();
      await _secureSessionService.deletePendingBidSessionCancellationId();
      _activeBidSessionId = null;
      _cleanupSubscriptions();
      _activeTrip = null;
      final fareAmount = acceptedBooking?.fareAmount;
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
    _nearestSearchCancelled = true;
    if (_isCreatingBidSession) {
      _cancelPendingBidSessionCreation = true;
      try {
        await _secureSessionService.requestPendingBidSessionCancellation();
        final sessionId = _activeBidSessionId;
        if (sessionId?.isNotEmpty == true) {
          await _secureSessionService.savePendingBidSessionCancellationId(
            sessionId!,
          );
        }
        emit(BookingSessionRecoveryInProgress(sessionId: sessionId ?? ''));
      } catch (error) {
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
          emit(const BookingSessionRecoveryInProgress(sessionId: ''));
          await _createOrRecoverPendingSession(newRequest: null, emit: emit);
          return;
        }
      } catch (error) {
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
      _pickupLat = null;
      _pickupLng = null;
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
    if (_isCreatingBidSession || _activeBidSessionId != null) return;
    _nearestSearchCancelled = true;
    _cleanupSubscriptions();
    _activeTrip = null;
    _pickupLat = null;
    _pickupLng = null;
    _pickupName = null;
    _dropoffLat = null;
    _dropoffLng = null;
    _totalTrips = null;
    ++_reviewsRequestGeneration;
    _isAutoAcceptingOffer = false;
    await _secureSessionService.deletePendingBidSessionCreation();
    await _secureSessionService.deletePendingBidSessionCancellationId();
    emit(const BookingInitial());
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
}
