import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driver_app/core/config/env_config.dart';
import 'package:flutter/foundation.dart';

import 'package:core_models/core_models.dart';
import 'package:driver_app/features/driver/presentation/bloc/ride/ride_flow_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Manages the sequential ride lifecycle: initial → en-route → waiting → in-transit → complete.
class RideFlowCubit extends Cubit<RideFlowState> {
  final RideRepository _repository;
  Timer? _waitTimer;
  int _elapsedWaitTime = 0;
  String? _activeRideId;

  String? get activeRideId => _activeRideId;

  RideFlowCubit({required RideRepository repository})
    : _repository = repository,
      super(RideFlowInitial());

  /// Driver accepted a ride request — begin navigating to pickup.
  Future<void> acceptRide({
    required String rideId,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
  }) async {
    _activeRideId = rideId;

    try {
      final baseUrl = EnvConfig.driverServiceUrl;
      await http.post(
        Uri.parse('$baseUrl/rides/$rideId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id': 'driver-123',
          'driver_name': 'Driver Xyrel',
          'driver_rating': '4.9',
          'vehicle_type': 'Bao Bao',
          'plate_number': 'ABC 1234',
        }),
      );
    } catch (e) {
      debugPrint('Error accepting ride on backend: $e');
    }

    emit(
      RideFlowEnRoutePickup(
        passengerName: passengerName,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
      ),
    );
  }

  // Driver has arrived at the pickup location — start waiting timer.
  Future<void> arriveAtPickup(String passengerName) async {
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;

    if (_activeRideId != null) {
      try {
        final baseUrl = EnvConfig.driverServiceUrl;
        await http.post(
          Uri.parse('$baseUrl/rides/$_activeRideId/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'arrived'}),
        );
      } catch (e) {
        debugPrint('Error updating status to arrived: $e');
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

  // Passenger is aboard — begin trip to destination.
  Future<void> startRide({
    required String passengerName,
    required double destLat,
    required double destLng,
    required double distanceKm,
  }) async {
    _waitTimer?.cancel();

    if (_activeRideId != null) {
      try {
        final baseUrl = EnvConfig.driverServiceUrl;
        await http.post(
          Uri.parse('$baseUrl/rides/$_activeRideId/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'in_transit'}),
        );
      } catch (e) {
        debugPrint('Error updating status to in_transit: $e');
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

  // Driver has reached the destination — compute and display the final fare.
  Future<void> endRide({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    _waitTimer?.cancel();

    if (_activeRideId != null) {
      try {
        final baseUrl = EnvConfig.driverServiceUrl;
        await http.post(
          Uri.parse('$baseUrl/rides/$_activeRideId/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'completed'}),
        );
      } catch (e) {
        debugPrint('Error updating status to completed: $e');
      }
    }

    try {
      final fareResult = await _repository.getFare(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
      emit(RideFlowComplete(fare: fareResult.totalFare));
    } catch (_) {
      emit(const RideFlowComplete(fare: 50.0));
    }
  }

  // Resets the ride flow back to idle.
  void reset() {
    _waitTimer?.cancel();
    _activeRideId = null;
    emit(RideFlowInitial());
  }

  @override
  Future<void> close() {
    _waitTimer?.cancel();
    return super.close();
  }
}
