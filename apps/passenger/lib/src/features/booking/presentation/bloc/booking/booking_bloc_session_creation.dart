part of 'booking_bloc.dart';

extension _BookingBlocSessionCreation on BookingBloc {
  Future<void> _onStartDirectBooking(
    StartDirectBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveBooking || _isCreatingBidSession) return;
    _stopNearbyDriverSearch();
    ++_bookingFlowGeneration;
    final targetDriver = event.targetDriver;
    final targetDriverId = int.tryParse(targetDriver.id);
    if (targetDriverId == null || targetDriverId <= 0) {
      _activeTrip = null;
      emit(
        BookingFailure(ErrorHandler.getErrorMessage(const ValidationFailure())),
      );
      return;
    }

    _isCreatingBidSession = true;
    _cancelPendingBidSessionCreation = false;
    _isAutoAcceptingOffer = false;
    _lastFailedDriverSearch = null;
    _setTripContext(
      event.trip,
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
      distanceKm: event.distanceKm,
      durationMinutes: event.durationMinutes,
    );
    emit(
      BookingSearching(
        isDirect: true,
        targetDriver: targetDriver,
        expiresAt: null,
      ),
    );
    await _requirePassengerAndCreate(
      request: _bookingRequest(
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
        distanceKm: event.distanceKm,
        durationMinutes: event.durationMinutes,
        targetDriverId: targetDriverId,
      ),
      targetDriver: targetDriver,
      emit: emit,
    );
  }

  Future<void> _onStartOpenBooking(
    StartOpenBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveBooking || _isCreatingBidSession) return;
    _stopNearbyDriverSearch();
    ++_bookingFlowGeneration;
    _isCreatingBidSession = true;
    _cancelPendingBidSessionCreation = false;
    _lastFailedDriverSearch = null;
    _setTripContext(
      event.trip,
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
      distanceKm: event.distanceKm,
      durationMinutes: event.durationMinutes,
    );
    emit(const BookingSearching(isDirect: false));
    await _requirePassengerAndCreate(
      request: _bookingRequest(
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
        distanceKm: event.distanceKm,
        durationMinutes: event.durationMinutes,
      ),
      emit: emit,
    );
  }

  Future<void> _requirePassengerAndCreate({
    required BookingSessionRequest request,
    required Emitter<BookingState> emit,
    Driver? targetDriver,
  }) async {
    String? passengerId;
    try {
      passengerId = await _secureSessionService.readPassengerId();
    } catch (error) {
      final cancellationRequested = _cancelPendingBidSessionCreation;
      _activeTrip = null;
      _isCreatingBidSession = false;
      _cancelPendingBidSessionCreation = false;
      emit(
        cancellationRequested
            ? const BookingCanceled()
            : BookingFailure(ErrorHandler.getErrorMessage(error)),
      );
      return;
    }
    if (passengerId?.trim().isNotEmpty != true) {
      final cancellationRequested = _cancelPendingBidSessionCreation;
      _activeTrip = null;
      _isCreatingBidSession = false;
      _cancelPendingBidSessionCreation = false;
      emit(
        cancellationRequested
            ? const BookingCanceled()
            : BookingFailure(ErrorHandler.getErrorMessage(const AuthFailure())),
      );
      return;
    }

    await _createOrRecoverPendingSession(
      newRequest: request,
      targetDriver: targetDriver,
      emit: emit,
    );
  }

  Future<void> _createOrRecoverPendingSession({
    required BookingSessionRequest? newRequest,
    required Emitter<BookingState> emit,
    Driver? targetDriver,
  }) async {
    if (!_isCreatingBidSession) {
      _isCreatingBidSession = true;
    }
    try {
      var pending = await _secureSessionService.readPendingBidSessionCreation();
      if (pending == null) {
        if (newRequest == null) return;
        final requestPayload = newRequest.encodePayload();
        final idempotencyKey = _newIdempotencyKey();
        await _secureSessionService.savePendingBidSessionCreation(
          idempotencyKey: idempotencyKey,
          requestPayload: requestPayload,
        );
        final cancelRequested = _cancelPendingBidSessionCreation;
        if (cancelRequested) {
          await _secureSessionService.requestPendingBidSessionCancellation();
        }
        pending = (
          idempotencyKey: idempotencyKey,
          requestPayload: requestPayload,
          cancelRequested: cancelRequested,
          sessionId: null,
        );
      }

      final storedRequest = BookingSessionRequest.fromPayload(
        pending.requestPayload,
      ).copyWith(idempotencyKey: pending.idempotencyKey);
      if (!storedRequest.isValid || storedRequest.customFareAmount <= 0) {
        throw const ValidationFailure(
          'The saved ride request is incomplete. Please start a new request.',
        );
      }

      _restoreTripContextFromRequest(storedRequest);
      final isDirect = storedRequest.targetDriverId != null;
      final matchingTargetDriver =
          isDirect &&
              storedRequest.targetDriverId.toString() == targetDriver?.id
          ? targetDriver
          : null;
      _cancelPendingBidSessionCreation =
          _cancelPendingBidSessionCreation || pending.cancelRequested;

      var sessionId = pending.sessionId;
      var bookingReference = '';
      if (sessionId == null || sessionId.isEmpty) {
        if (state case BookingSearching(:final sessionId?)
            when sessionId.isNotEmpty) {
          emit(
            BookingSearching(
              isDirect: isDirect,
              targetDriver: matchingTargetDriver,
              sessionId: null,
            ),
          );
        } else if (state is! BookingSearching) {
          emit(
            BookingSearching(
              isDirect: isDirect,
              targetDriver: matchingTargetDriver,
              sessionId: null,
            ),
          );
        }
        final createResult = await _bookingRepository.createSessionResult(
          storedRequest,
        );
        switch (createResult) {
          case Err(:final failure):
            if (failure is ValidationFailure) {
              await _secureSessionService.deletePendingBidSessionCreation();
              _activeTrip = null;
              if (isClosed) return;
              emit(
                _cancelPendingBidSessionCreation
                    ? const BookingCanceled()
                    : BookingFailure(failure.message),
              );
              return;
            }
            throw failure;
          case Ok(value: final createdSession):
            sessionId = createdSession.id;
            bookingReference = createdSession.bookingReference;
            await _secureSessionService.attachPendingBidSessionId(sessionId);
        }
      }

      final resolvedSessionId = sessionId;
      _activeBidSessionId = resolvedSessionId;
      await _secureSessionService.saveActiveBidSessionId(resolvedSessionId);
      final currentPending = await _secureSessionService
          .readPendingBidSessionCreation();
      final cancellationRequested =
          _cancelPendingBidSessionCreation ||
          currentPending?.cancelRequested == true;
      if (cancellationRequested) {
        await _secureSessionService.savePendingBidSessionCancellationId(
          resolvedSessionId,
        );
        if (isClosed) return;
        emit(BookingSessionRecoveryInProgress(sessionId: resolvedSessionId));
        await _cancelPersistedBookingSession(resolvedSessionId, emit);
        return;
      }

      await _secureSessionService.deletePendingBidSessionCreation();
      final cancellationSessionId = await _secureSessionService
          .readPendingBidSessionCancellationId();
      if (cancellationSessionId == resolvedSessionId) {
        if (isClosed) return;
        emit(BookingSessionRecoveryInProgress(sessionId: resolvedSessionId));
        await _cancelPersistedBookingSession(resolvedSessionId, emit);
        return;
      }
      if (isClosed) return;
      emit(
        BookingSearching(
          isDirect: isDirect,
          targetDriver: matchingTargetDriver,
          sessionId: resolvedSessionId,
          bookingReference: bookingReference,
        ),
      );
      _subscribeToSession(resolvedSessionId);
    } catch (error) {
      if (isClosed) return;
      final sessionId = _activeBidSessionId ?? '';
      emit(
        BookingSessionRecoveryFailure(
          sessionId: sessionId,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
    } finally {
      _isCreatingBidSession = false;
      _cancelPendingBidSessionCreation = false;
    }
  }

  Future<void> _cancelPersistedBookingSession(
    String sessionId,
    Emitter<BookingState> emit, {
    bool expired = false,
  }) async {
    _isCancellingBooking = true;
    if (expired) {
      _captureFailedDriverSearch();
    } else {
      _lastFailedDriverSearch = null;
    }
    final BookingState terminalState = expired
        ? BookingFailure(
            'This request expired before a driver accepted it.',
            isRequestExpired: true,
            sessionId: sessionId,
            bookingReference: state.publicBookingReference,
          )
        : const BookingCanceled();
    try {
      final result = await _bookingRepository
          .cancelSessionResult(sessionId)
          .timeout(const Duration(seconds: 5));
      final Failure failure;
      switch (result) {
        case Ok():
          await _clearPendingBooking(sessionId);
          if (isClosed) return;
          emit(terminalState);
          return;
        case Err(failure: final cancelFailure):
          failure = cancelFailure;
      }

      final refreshResult = await _bookingRepository.fetchSessionResult(
        sessionId,
      );
      switch (refreshResult) {
        case Ok(value: final snapshot):
          if (snapshot.isAccepted) {
            await _recoverAcceptedSession(snapshot, emit);
            return;
          }
          if (expired ||
              snapshot.isCancelled ||
              snapshot.isExpired ||
              snapshot.isDeclined) {
            await _clearPendingBooking(sessionId);
            if (isClosed) return;
            emit(terminalState);
            return;
          }
          if (isClosed) return;
          emit(
            BookingSessionRecoveryFailure(
              sessionId: sessionId,
              message: failure.message,
            ),
          );
        case Err(failure: final refreshFailure):
          if (expired) {
            await _clearPendingBooking(sessionId);
            if (isClosed) return;
            emit(terminalState);
            return;
          }
          if (isClosed) return;
          emit(
            BookingSessionRecoveryFailure(
              sessionId: sessionId,
              message: refreshFailure.message,
            ),
          );
      }
    } catch (error) {
      if (expired) {
        await _clearPendingBooking(sessionId);
        if (isClosed) return;
        emit(terminalState);
        return;
      }
      if (isClosed) return;
      emit(
        BookingSessionRecoveryFailure(
          sessionId: sessionId,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
    } finally {
      _isCancellingBooking = false;
    }
  }

  Future<void> _clearPendingBooking(String sessionId) async {
    if (_activeBidSessionId == sessionId) _activeBidSessionId = null;
    await _secureSessionService.deleteActiveBidSessionId();
    await _secureSessionService.deletePendingBidSessionCreation();
    await _secureSessionService.deletePendingBidSessionCancellationId();
    _cleanupSubscriptions();
    _activeTrip = null;
    _pickupLat = null;
    _pickupLng = null;
    _pickupName = null;
    _distanceKm = null;
    _durationMinutes = null;
  }

  String _newIdempotencyKey() => List<String>.generate(
    32,
    (_) => _idempotencyRandom.nextInt(16).toRadixString(16),
  ).join();

  void _setTripContext(
    BidSessionTrip trip, {
    required double pickupLat,
    required double pickupLng,
    double? distanceKm,
    double? durationMinutes,
  }) {
    _activeTrip = trip;
    _pickupLat = pickupLat;
    _pickupLng = pickupLng;
    _pickupName = _pickupNameForTrip(trip);
    _distanceKm = distanceKm;
    _durationMinutes = durationMinutes;
  }

  void _restoreTripContextFromRequest(BookingSessionRequest request) {
    final destination = Place(
      id: 'request-pending',
      name: request.dropoffName,
      fullAddress: request.dropoffName,
      latitude: request.dropoffLatitude,
      longitude: request.dropoffLongitude,
    );
    _activeTrip = BidSessionTrip(
      fare: request.customFareAmount / 100,
      destination: destination,
      distance: '${request.distanceKm.toStringAsFixed(1)} km',
      duration: '${request.durationMinutes.round()} min',
      pickupAddress: request.pickupName,
      passengerNote: request.passengerNote,
    );
    _pickupLat = request.pickupLatitude;
    _pickupLng = request.pickupLongitude;
    _pickupName = request.pickupName;
    _distanceKm = request.distanceKm;
    _durationMinutes = request.durationMinutes;
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
      pickupLatitude: pickupLat,
      pickupLongitude: pickupLng,
      pickupName: _pickupName ?? _pickupNameForTrip(trip),
      dropoffLatitude: trip.destination.latitude,
      dropoffLongitude: trip.destination.longitude,
      dropoffName: trip.destination.name,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      targetDriverId: targetDriverId,
      customFareAmount: (trip.fare * 100).round(),
      passengerNote: trip.passengerNote,
    );
  }
}
