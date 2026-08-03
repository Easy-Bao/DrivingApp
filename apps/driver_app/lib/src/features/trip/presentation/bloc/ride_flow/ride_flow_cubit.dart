import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/data_sources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_state.dart';

class RideFlowCubit extends Cubit<RideFlowState> {
  final TripRemoteDataSource _tripRemoteDataSource;
  final SecureSessionService _sessionService;

  String? _activeRideId;
  Timer? _waitTimer;
  int _elapsedWaitTime = 0;

  RideFlowCubit({
    required TripRemoteDataSource tripRemoteDataSource,
    required SecureSessionService sessionService,
  }) : _tripRemoteDataSource = tripRemoteDataSource,
       _sessionService = sessionService,
       super(const RideFlowInitial());

  String? get activeRideId => _activeRideId;

  void resumeRide({
    required String rideId,
    required String status,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
  }) {
    _activeRideId = rideId;
    if (status == 'arrived') {
      emit(
        RideFlowWaitingPassenger(
          passengerName: passengerName,
          waitTimeSeconds: 0,
        ),
      );
    } else if (status == 'in_transit') {
      emit(
        RideFlowInTransit(
          passengerName: passengerName,
          destLat: destLat,
          destLng: destLng,
          distanceKm: 3.2,
        ),
      );
    } else {
      emit(
        RideFlowEnRoutePickup(
          passengerName: passengerName,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
        ),
      );
    }
  }

  Future<void> acceptRide({
    required String rideId,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
  }) async {
    _activeRideId = rideId;

    final driverId = await _sessionService.readDriverId();
    if (driverId == null || driverId.isEmpty) {
      emit(const RideFlowError('Driver session is unavailable. Please sign in again.'));
      return;
    }

    try {
      final success = await _tripRemoteDataSource.acceptRide(
        tripId: rideId,
        driverId: driverId,
      );

      if (!success) {
        emit(const RideFlowError('Failed to accept ride on backend.'));
        return;
      }

      emit(
        RideFlowEnRoutePickup(
          passengerName: passengerName,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
        ),
      );
    } catch (error) {
      dev.log('Error accepting ride on backend: $error');
      emit(RideFlowError(error.toString()));
    }
  }

  Future<void> arriveAtPickup(String passengerName) async {
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;

    if (_activeRideId != null) {
      try {
        await _tripRemoteDataSource.updateRideStatus(
          tripId: _activeRideId!,
          status: 'arrived',
        );
      } catch (error) {
        dev.log('Error updating status to arrived: $error');
      }
    }

    emit(
      RideFlowWaitingPassenger(
        passengerName: passengerName,
        waitTimeSeconds: 0,
      ),
    );
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) return;
      _elapsedWaitTime++;
      emit(
        RideFlowWaitingPassenger(
          passengerName: passengerName,
          waitTimeSeconds: _elapsedWaitTime,
        ),
      );
    });
  }

  Future<void> startRide({
    required String passengerName,
    required double destLat,
    required double destLng,
    required double distanceKm,
  }) async {
    _waitTimer?.cancel();

    if (_activeRideId != null) {
      try {
        await _tripRemoteDataSource.updateRideStatus(
          tripId: _activeRideId!,
          status: 'in_transit',
        );
      } catch (error) {
        dev.log('Error updating status to in_transit: $error');
      }
    }

    emit(
      RideFlowInTransit(
        passengerName: passengerName,
        destLat: destLat,
        destLng: destLng,
        distanceKm: distanceKm,
      ),
    );
  }

  Future<void> endRide({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    _waitTimer?.cancel();

    if (_activeRideId != null) {
      try {
        await _tripRemoteDataSource.updateRideStatus(
          tripId: _activeRideId!,
          status: 'completed',
        );
      } catch (error) {
        dev.log('Error updating status to completed: $error');
      }
    }

    final fare = distanceKm * 15 + 30;
    emit(RideFlowComplete(fare: fare));
  }

  void reset() {
    _waitTimer?.cancel();
    _activeRideId = null;
    emit(const RideFlowInitial());
  }

  @override
  Future<void> close() {
    _waitTimer?.cancel();
    return super.close();
  }
}
