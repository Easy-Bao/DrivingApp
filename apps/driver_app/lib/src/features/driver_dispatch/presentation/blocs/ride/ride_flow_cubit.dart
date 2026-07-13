import 'dart:async';
import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/src/core/services/driver_api_service.dart';

import 'ride_flow_state.dart';

class RideFlowCubit extends Cubit<RideFlowState> {
  final RideRepository _repository;
  final DriverApiService _apiService;
  String? _activeRideId;
  Timer? _waitTimer;
  int _elapsedWaitTime = 0;

  RideFlowCubit({
    required RideRepository repository,
    required DriverApiService apiService,
  }) : _repository = repository,
       _apiService = apiService,
       super(RideFlowInitial());

  String? get activeRideId => _activeRideId;

  Future<void> acceptRide({
    required String rideId,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
  }) async {
    _activeRideId = rideId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driver_id') ?? 'driver-123';
      final driverName = prefs.getString('driver_name') ?? 'Driver Xyrel';
      final vehicleType = prefs.getString('vehicle_type') ?? 'Bao Bao';
      final plateNumber = prefs.getString('plate_number') ?? 'ABC 1234';
      final rating = prefs.getString('rating') ?? '4.9';

      await _apiService.acceptRide(
        rideId: rideId,
        driverId: driverId,
        driverName: driverName,
        driverRating: rating,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
      );
    } catch (error) {
      debugPrint(
        'Error accepting ride on backend: ${ErrorHandler.getErrorMessage(error)}',
      );
    }

    emit(
      RideFlowEnRoutePickup(
        passengerName: passengerName,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
      ),
    );
  }

  Future<void> resumeRide({
    required String rideId,
    required String status,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    double distanceKm = 5.2,
  }) async {
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
          distanceKm: distanceKm,
        ),
      );
    } else {
      emit(RideFlowInitial());
    }
  }

  Future<void> arriveAtPickup(String passengerName) async {
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;

    if (_activeRideId != null) {
      try {
        await _apiService.updateRideStatus(_activeRideId!, 'arrived');
      } catch (error) {
        debugPrint(
          'Error updating status to arrived: ${ErrorHandler.getErrorMessage(error)}',
        );
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
        await _apiService.updateRideStatus(_activeRideId!, 'in_transit');
      } catch (error) {
        debugPrint(
          'Error updating status to in_transit: ${ErrorHandler.getErrorMessage(error)}',
        );
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
        await _apiService.updateRideStatus(_activeRideId!, 'completed');
      } catch (error) {
        debugPrint(
          'Error updating status to completed: ${ErrorHandler.getErrorMessage(error)}',
        );
      }
    }

    try {
      final fareResult = await _repository.getFare(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
      emit(RideFlowComplete(fare: fareResult.totalFare));
    } catch (error) {
      debugPrint(
        'Error loading dynamic fare calculation: ${ErrorHandler.getErrorMessage(error)}. Falling back to default.',
      );
      emit(const RideFlowComplete(fare: 50.0));
    }
  }

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
