import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_state.dart';
import 'package:shared_core/shared_core.dart';

class RideFlowCubit extends Cubit<RideFlowState> {
  final TripRemoteDataSource _tripRemoteDataSource;
  final SecureSessionService _sessionService;

  String? _activeRideId;
  String? _activePassengerId;
  String? _activePassengerName;
  Timer? _waitTimer;
  int _elapsedWaitTime = 0;

  RideFlowCubit({
    required TripRemoteDataSource tripRemoteDataSource,
    required SecureSessionService sessionService,
  }) : _tripRemoteDataSource = tripRemoteDataSource,
       _sessionService = sessionService,
       super(const RideFlowInitial());

  String? get activeRideId => _activeRideId;
  String? get activePassengerId => _activePassengerId;
  String get activePassengerName => _activePassengerName ?? 'Passenger';

  void resumeRide({
    required String rideId,
    required String status,
    required String passengerName,
    String? passengerId,
    double? distanceKm,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
  }) {
    _activeRideId = rideId;
    _activePassengerId = passengerId;
    _activePassengerName = passengerName;
    if (status == 'arrived') {
      emit(
        RideFlowWaitingPassenger(
          passengerName: passengerName,
          waitTimeSeconds: 0,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
    } else if (status == 'in_transit') {
      emit(
        RideFlowInTransit(
          passengerName: passengerName,
          destLat: destLat,
          destLng: destLng,
          distanceKm: distanceKm,
          passengerLat: pickupLat,
          passengerLng: pickupLng,
        ),
      );
    } else {
      emit(
        RideFlowNavigatingToPickup(
          passengerName: passengerName,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
    }
  }

  Future<void> acceptRide({
    required String rideId,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    _activeRideId = rideId;
    _activePassengerName = passengerName;

    final driverId = await _sessionService.readDriverId();
    if (driverId == null || driverId.isEmpty) {
      emit(
        const RideFlowError(
          'Driver session is unavailable. Please sign in again.',
        ),
      );
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
        RideFlowNavigatingToPickup(
          passengerName: passengerName,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
    } catch (error) {
      dev.log('Error accepting ride on backend: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> arriveAtPickup(
    String passengerName, {
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;

    if (_activeRideId != null) {
      try {
        final updated = await _tripRemoteDataSource.updateRideStatus(
          tripId: _activeRideId!,
          status: 'arrived',
        );
        if (!updated) {
          emit(
            const RideFlowError('Unable to confirm arrival with the server.'),
          );
          return;
        }
      } catch (error) {
        dev.log('Error updating status to arrived: $error');
        emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
        return;
      }
    }

    emit(
      RideFlowWaitingPassenger(
        passengerName: passengerName,
        waitTimeSeconds: 0,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destLat: destLat,
        destLng: destLng,
      ),
    );
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) return;
      _elapsedWaitTime++;
      emit(
        RideFlowWaitingPassenger(
          passengerName: passengerName,
          waitTimeSeconds: _elapsedWaitTime,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        ),
      );
    });
  }

  Future<bool> startRide({
    required String passengerName,
    required double? destLat,
    required double? destLng,
    required double distanceKm,
    double? passengerLat,
    double? passengerLng,
  }) async {
    _waitTimer?.cancel();

    if (destLat == null || destLng == null) {
      emit(const RideFlowError('The destination coordinates are unavailable.'));
      return false;
    }

    if (_activeRideId != null) {
      try {
        final updated = await _tripRemoteDataSource.updateRideStatus(
          tripId: _activeRideId!,
          status: 'in_transit',
        );
        if (!updated) {
          emit(
            const RideFlowError(
              'Another passenger is already in transit. Complete that trip first.',
            ),
          );
          return false;
        }
      } catch (error) {
        dev.log('Error updating status to in_transit: $error');
        emit(const RideFlowError('Unable to start this trip right now.'));
        return false;
      }
    }

    emit(
      RideFlowInTransit(
        passengerName: passengerName,
        destLat: destLat,
        destLng: destLng,
        distanceKm: distanceKm,
        passengerLat: passengerLat,
        passengerLng: passengerLng,
      ),
    );
    return true;
  }

  Future<Map<String, dynamic>?> _loadCompletedRide() async {
    _waitTimer?.cancel();

    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) {
      emit(const RideFlowError('This trip is no longer active.'));
      return null;
    }

    try {
      final ride = await _tripRemoteDataSource.getRideStatus(rideId);
      _activePassengerId ??= ride['passenger_id']?.toString();
      _activePassengerName ??= ride['passenger_name']?.toString();
      final status = ride['status']?.toString();
      if (status != 'completed') {
        final updated = await _tripRemoteDataSource.updateRideStatus(
          tripId: rideId,
          status: 'completed',
        );
        if (!updated) {
          emit(
            const RideFlowError('Unable to complete this trip on the server.'),
          );
          return null;
        }
      }
      return ride;
    } catch (error) {
      dev.log('Error completing ride on backend: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      return null;
    }
  }

  Future<double?> completeRide() async {
    final ride = await _loadCompletedRide();
    if (ride == null) return null;

    final fareCentavos = (ride['fare_centavos'] as num?)?.toDouble();
    if (fareCentavos == null || fareCentavos <= 0) {
      emit(const RideFlowError('The server did not return a payable fare.'));
      return null;
    }
    return fareCentavos / 100;
  }

  Future<double?> confirmCashPayment() async {
    final rideId = _activeRideId;
    if (rideId == null || rideId.isEmpty) {
      emit(const RideFlowError('This trip is no longer active.'));
      return null;
    }

    try {
      final settled = await _tripRemoteDataSource.settleCash(rideId);
      final fareCentavos = (settled['fare_centavos'] as num?)?.toDouble();
      if (fareCentavos == null || fareCentavos <= 0) {
        emit(const RideFlowError('The server did not return a payable fare.'));
        return null;
      }
      final finalFare = fareCentavos / 100;
      emit(RideFlowComplete(fare: finalFare));
      return finalFare;
    } catch (error) {
      dev.log('Error settling cash trip: $error');
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
      return null;
    }
  }

  Future<double?> endRide() async {
    final completedFare = await completeRide();
    if (completedFare == null) return null;
    return confirmCashPayment();
  }

  void reset() {
    _waitTimer?.cancel();
    _activeRideId = null;
    _activePassengerId = null;
    _activePassengerName = null;
    emit(const RideFlowInitial());
  }

  @override
  Future<void> close() {
    _waitTimer?.cancel();
    return super.close();
  }
}
