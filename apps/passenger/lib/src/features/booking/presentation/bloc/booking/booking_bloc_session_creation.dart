part of 'booking_bloc.dart';

extension _BookingBlocSessionCreation on BookingBloc {
  Future<void> _onStartDirectBooking(
    StartDirectBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveBooking) return;
    final targetDriver = event.targetDriver;
    final targetDriverId = int.tryParse(targetDriver.id);
    if (targetDriverId == null || targetDriverId <= 0) {
      _activeTrip = null;
      emit(
        BookingFailure(ErrorHandler.getErrorMessage(const ValidationFailure())),
      );
      return;
    }
    _isAutoAcceptingOffer = false;
    _activeTrip = event.trip;
    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = this._pickupNameForTrip(event.trip);
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;
    emit(BookingSearching(isDirect: true, targetDriver: targetDriver));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      _activeTrip = null;
      emit(BookingFailure(ErrorHandler.getErrorMessage(const AuthFailure())));
      return;
    }

    try {
      String? sessionId;
      Failure? failure;
      (await _bookingRepository.createSessionResult(
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
      unawaited(_secureSessionService.saveActiveBidSessionId(sessionId!));
      this._subscribeToSession(sessionId!);
    } catch (error) {
      _activeTrip = null;
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> _onStartOpenBooking(
    StartOpenBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveBooking) return;
    _activeTrip = event.trip;
    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = this._pickupNameForTrip(event.trip);
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;
    emit(const BookingSearching(isDirect: false));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      _activeTrip = null;
      emit(BookingFailure(ErrorHandler.getErrorMessage(const AuthFailure())));
      return;
    }

    try {
      String? sessionId;
      Failure? failure;
      (await _bookingRepository.createSessionResult(
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
      unawaited(_secureSessionService.saveActiveBidSessionId(sessionId!));
      this._subscribeToSession(sessionId!);
    } catch (error) {
      _activeTrip = null;
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
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
      pickupName: _pickupName ?? this._pickupNameForTrip(trip),
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
