part of 'booking_bloc.dart';

extension _BookingBlocSessionRecovery on BookingBloc {
  Future<void> _onRestoreActiveBooking(
    RestoreActiveBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (state is! BookingSessionRecoveryFailure &&
        (hasActiveDriverSearch || _activeBidSessionId != null)) {
      return;
    }

    String? sessionId;
    PendingBidSessionCreation? pendingCreation;
    try {
      final activeRideId = (await _secureSessionService.readActiveRideId())
          ?.trim();
      if (activeRideId?.isNotEmpty == true) {
        await _secureSessionService.deleteActiveBidSessionId();
        await _secureSessionService.deletePendingBidSessionCreation();
        await _secureSessionService.deletePendingBidSessionCancellationId();
        return;
      }
      sessionId = (await _secureSessionService.readActiveBidSessionId())
          ?.trim();
      pendingCreation = await _secureSessionService
          .readPendingBidSessionCreation();
      final pendingCancellationId = await _secureSessionService
          .readPendingBidSessionCancellationId();
      if (sessionId?.isNotEmpty != true) {
        sessionId = pendingCancellationId ?? pendingCreation?.sessionId;
      }
      if (sessionId?.isNotEmpty == true) {
        await _secureSessionService.saveActiveBidSessionId(sessionId!);
      }
    } catch (error) {
      dev.log('Unable to read the saved passenger booking: $error');
      emit(
        BookingSessionRecoveryFailure(
          sessionId: sessionId ?? '',
          message: 'Your saved request could not be read. Please retry.',
        ),
      );
      return;
    }

    if (isClosed) return;
    if (sessionId == null || sessionId.isEmpty) {
      if (pendingCreation == null) return;
      emit(const BookingSessionRecoveryInProgress(sessionId: ''));
      await _createOrRecoverPendingSession(newRequest: null, emit: emit);
      return;
    }

    _activeBidSessionId = sessionId;
    emit(BookingSessionRecoveryInProgress(sessionId: sessionId));
    try {
      BidSessionSnapshot? snapshot;
      Failure? failure;
      (await _bookingRepository.fetchSessionResult(sessionId))
          .fold((value) => failure = value, (value) => snapshot = value);
      if (isClosed || _activeBidSessionId != sessionId) return;
      if (snapshot == null) {
        throw failure ??
            const ServerFailure('The saved request could not be loaded.');
      }
      if (snapshot!.id != sessionId) {
        throw const ValidationFailure(
          'The saved request did not match the server response.',
        );
      }

      if (snapshot!.isAccepted) {
        await _recoverAcceptedSession(snapshot!, emit);
        return;
      }

      _restoreTripContext(snapshot!);
      if (snapshot!.isExpired) {
        await _clearRecoveredRequest(sessionId);
        emit(
          BookingFailure(
            'No driver accepted this request before it expired.',
            isRequestExpired: true,
            sessionId: sessionId,
            bookingReference: snapshot!.bookingReference,
          ),
        );
        return;
      }

      if (snapshot!.isCancelled) {
        await _clearRecoveredRequest(sessionId);
        emit(const BookingCanceled());
        return;
      }

      if (!snapshot!.isOpen) {
        throw const ValidationFailure(
          'The saved request has an unknown status. Please retry.',
        );
      }

      final pendingCancellationId = await _secureSessionService
          .readPendingBidSessionCancellationId();
      final shouldCancel =
          pendingCancellationId == sessionId ||
          (pendingCreation?.sessionId == sessionId &&
              pendingCreation?.cancelRequested == true);
      if (shouldCancel) {
        if (pendingCancellationId != sessionId) {
          await _secureSessionService.savePendingBidSessionCancellationId(
            sessionId,
          );
        }
        await _cancelPersistedBookingSession(sessionId, emit);
        return;
      }

      if (pendingCreation?.sessionId == sessionId) {
        await _secureSessionService.deletePendingBidSessionCreation();
      } else if (pendingCreation != null) {
        throw const ValidationFailure(
          'Another saved request still needs to be recovered. Please retry.',
        );
      }

      emit(
        BookingSearching(
          isDirect: snapshot!.targetDriverId != null,
          sessionId: sessionId,
          expiresAt: snapshot!.expiresAt,
          bookingReference: snapshot!.bookingReference,
        ),
      );
      _subscribeToSession(sessionId);
    } catch (error) {
      if (isClosed || _activeBidSessionId != sessionId) return;
      emit(
        BookingSessionRecoveryFailure(
          sessionId: sessionId,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  Future<void> _clearRecoveredRequest(String sessionId) async {
    if (_activeBidSessionId == sessionId) _activeBidSessionId = null;
    await _secureSessionService.deleteActiveBidSessionId();
    await _secureSessionService.deletePendingBidSessionCreation();
    await _secureSessionService.deletePendingBidSessionCancellationId();
    _cleanupSubscriptions();
    _activeTrip = null;
  }

  Future<void> _recoverAcceptedSession(
    BidSessionSnapshot snapshot,
    Emitter<BookingState> emit,
  ) async {
    final rideId = snapshot.rideId?.trim() ?? '';
    if (rideId.isEmpty) {
      emit(
        BookingSessionRecoveryFailure(
          sessionId: snapshot.id,
          message: 'The accepted trip is being recovered. Please retry.',
        ),
      );
      return;
    }
    try {
      await _secureSessionService.saveActiveRideId(rideId);
      await _secureSessionService.deleteActiveBidSessionId();
      await _secureSessionService.deletePendingBidSessionCreation();
      await _secureSessionService.deletePendingBidSessionCancellationId();
      if (isClosed || _activeBidSessionId != snapshot.id) return;
      _activeBidSessionId = null;
      _activeTrip = null;
      _cleanupSubscriptions();
      emit(
        BookingRideRecovered(
          sessionId: snapshot.id,
          rideId: rideId,
          bookingReference: snapshot.bookingReference,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        BookingSessionRecoveryFailure(
          sessionId: snapshot.id,
          message: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  void _restoreTripContext(BidSessionSnapshot snapshot) {
    final pickupLatitude = snapshot.pickupLatitude;
    final pickupLongitude = snapshot.pickupLongitude;
    final dropoffLatitude = snapshot.dropoffLatitude;
    final dropoffLongitude = snapshot.dropoffLongitude;
    final distanceKm = snapshot.distanceKm;
    final durationMinutes = snapshot.durationMinutes;
    final fareAmount = snapshot.customFareAmount ?? snapshot.offeredFareAmount;
    final pickupName = snapshot.pickupName?.trim() ?? '';
    final dropoffName = snapshot.dropoffName?.trim() ?? '';

    if (pickupLatitude == null ||
        pickupLongitude == null ||
        dropoffLatitude == null ||
        dropoffLongitude == null ||
        distanceKm == null ||
        durationMinutes == null ||
        fareAmount == null ||
        fareAmount <= 0 ||
        !pickupLatitude.isFinite ||
        !pickupLongitude.isFinite ||
        !dropoffLatitude.isFinite ||
        !dropoffLongitude.isFinite ||
        pickupLatitude.abs() > 90 ||
        dropoffLatitude.abs() > 90 ||
        pickupLongitude.abs() > 180 ||
        dropoffLongitude.abs() > 180 ||
        !distanceKm.isFinite ||
        distanceKm <= 0 ||
        !durationMinutes.isFinite ||
        durationMinutes <= 0 ||
        pickupName.isEmpty ||
        dropoffName.isEmpty) {
      throw const ValidationFailure(
        'The saved request is missing route details. Please retry.',
      );
    }

    final destination = Place(
      id: 'request-${snapshot.id}',
      name: dropoffName,
      fullAddress: dropoffName,
      latitude: dropoffLatitude,
      longitude: dropoffLongitude,
    );
    _activeTrip = BidSessionTrip(
      fare: fareAmount / 100,
      destination: destination,
      distance: '${distanceKm.toStringAsFixed(1)} km',
      duration: '${durationMinutes.round()} min',
      pickupAddress: pickupName,
      passengerNote: snapshot.passengerNote,
    );
    _pickupLat = pickupLatitude;
    _pickupLng = pickupLongitude;
    _pickupName = pickupName;
    _dropoffLat = dropoffLatitude;
    _dropoffLng = dropoffLongitude;
  }
}
