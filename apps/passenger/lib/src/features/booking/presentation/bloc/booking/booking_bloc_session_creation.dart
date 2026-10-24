part of 'booking_bloc.dart';

extension _BookingBlocSessionCreation on BookingBloc {
  Future<void> _onStartDirectBooking(
    StartDirectBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveBooking || _isCreatingBidSession) return;
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
    _setTripContext(
      event.trip,
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
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
    _isCreatingBidSession = true;
    _cancelPendingBidSessionCreation = false;
    _setTripContext(
      event.trip,
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
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
    DriverModel? targetDriver,
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
    DriverModel? targetDriver,
  }) async {
    if (!_isCreatingBidSession) {
      _isCreatingBidSession = true;
    }
    try {
      var pending = await _secureSessionService.readPendingBidSessionCreation();
      if (pending == null) {
        if (newRequest == null) return;
        final requestPayload = jsonEncode(newRequest.toJson());
        final idempotencyKey = _newIdempotencyKey();
        await _secureSessionService.savePendingBidSessionCreation(
          idempotencyKey: idempotencyKey,
          requestPayload: requestPayload,
        );
        if (_cancelPendingBidSessionCreation) {
          await _secureSessionService.requestPendingBidSessionCancellation();
        }
        pending = (
          idempotencyKey: idempotencyKey,
          requestPayload: requestPayload,
          cancelRequested: false,
          sessionId: null,
        );
      }

      final decodedPayload = jsonDecode(pending.requestPayload);
      if (decodedPayload is! Map) {
        throw const FormatException('The saved ride request is invalid.');
      }
      final storedRequest = BookingSessionRequest.fromJson(
        Map<String, dynamic>.from(decodedPayload),
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
      _cancelPendingBidSessionCreation = pending.cancelRequested;

      var sessionId = pending.sessionId;
      var bookingReference = '';
      if (sessionId == null || sessionId.isEmpty) {
        if (state is! BookingSearching ||
            (state as BookingSearching).sessionId != null) {
          emit(
            BookingSearching(
              isDirect: isDirect,
              targetDriver: matchingTargetDriver,
              sessionId: null,
            ),
          );
        }
        BidSessionSnapshot? createdSession;
        Failure? failure;
        (await _bookingRepository.createSessionResult(
          storedRequest,
        )).fold((value) => failure = value, (value) => createdSession = value);
        if (createdSession == null) {
          if (failure is ValidationFailure) {
            await _secureSessionService.deletePendingBidSessionCreation();
            _activeTrip = null;
            emit(
              _cancelPendingBidSessionCreation
                  ? const BookingCanceled()
                  : BookingFailure(failure!.message),
            );
            return;
          }
          throw failure!;
        }
        sessionId = createdSession!.id;
        bookingReference = createdSession!.bookingReference;
        await _secureSessionService.attachPendingBidSessionId(sessionId);
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
        emit(BookingSessionRecoveryInProgress(sessionId: resolvedSessionId));
        await _cancelPersistedBookingSession(resolvedSessionId, emit);
        return;
      }

      await _secureSessionService.deletePendingBidSessionCreation();
      final cancellationSessionId = await _secureSessionService
          .readPendingBidSessionCancellationId();
      if (cancellationSessionId == resolvedSessionId) {
        emit(BookingSessionRecoveryInProgress(sessionId: resolvedSessionId));
        await _cancelPersistedBookingSession(resolvedSessionId, emit);
        return;
      }
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
      var canceled = false;
      Failure? failure;
      result.fold((value) => failure = value, (_) => canceled = true);
      if (canceled) {
        await _clearPendingBooking(sessionId);
        emit(terminalState);
        return;
      }
      failure ??= const ServerFailure(
        'The request cancellation is unconfirmed.',
      );

      BidSessionSnapshot? snapshot;
      Failure? refreshFailure;
      (await _bookingRepository.fetchSessionResult(sessionId))
          .fold((value) => refreshFailure = value, (value) => snapshot = value);
      if (snapshot?.isAccepted == true) {
        await _recoverAcceptedSession(snapshot!, emit);
        return;
      }
      if (snapshot?.isCancelled == true ||
          snapshot?.isExpired == true ||
          snapshot?.isDeclined == true) {
        await _clearPendingBooking(sessionId);
        emit(terminalState);
        return;
      }
      emit(
        BookingSessionRecoveryFailure(
          sessionId: sessionId,
          message: refreshFailure?.message ?? failure!.message,
        ),
      );
    } catch (error) {
      emit(
        BookingSessionRecoveryFailure(
          sessionId: sessionId,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
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
    _dropoffLat = null;
    _dropoffLng = null;
  }

  String _newIdempotencyKey() => List<String>.generate(
    32,
    (_) => _idempotencyRandom.nextInt(16).toRadixString(16),
  ).join();

  void _setTripContext(
    BidSessionTrip trip, {
    required double pickupLat,
    required double pickupLng,
  }) {
    _activeTrip = trip;
    _pickupLat = pickupLat;
    _pickupLng = pickupLng;
    _pickupName = _pickupNameForTrip(trip);
    _dropoffLat = trip.destination.latitude;
    _dropoffLng = trip.destination.longitude;
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
    _dropoffLat = request.dropoffLatitude;
    _dropoffLng = request.dropoffLongitude;
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
