import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:driver_services/driver_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:session_service/session_service.dart';

import 'ride_flow_state.dart';

class RideFlowCubit extends Cubit<RideFlowState> {
  final RideRepository _repository;
  final TripApiService _apiService;
  final DriverSessionService _sessionService;
  String? _activeRideId;
  Timer? _waitTimer;
  int _elapsedWaitTime = 0;

  RideFlowCubit({
    required RideRepository repository,
    required TripApiService apiService,
    required DriverSessionService sessionService,
  }) : _repository = repository,
       _apiService = apiService,
       _sessionService = sessionService,
       super(RideFlowInitial());

  String? get activeRideId => _activeRideId;

  Future<void> acceptRide({
    required String rideId,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
  }) async {
    _activeRideId = rideId;

    final driverProfile = await _sessionService.getProfile();
    if (driverProfile == null) {
      emit(const RideFlowError('No active driver profile session found.'));
      return;
    }

    try {
      final success = await _apiService.acceptRide(
        rideId: rideId,
        driverId: driverProfile.id,
        driverName: driverProfile.name,
        driverRating: driverProfile.rating,
        vehicleType: driverProfile.vehicleType,
        plateNumber: driverProfile.plateNumber,
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
      debugPrint(
        'Error accepting ride on backend: ${ErrorHandler.getErrorMessage(error)}',
      );
      emit(RideFlowError(ErrorHandler.getErrorMessage(error)));
    }
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

    final fareResult = await _repository.getFare(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
    fareResult.fold((failure) {
      debugPrint(
        'Error loading dynamic fare calculation: ${failure.message}. Falling back to default.',
      );
      emit(const RideFlowComplete(fare: 50.0));
    }, (fare) => emit(RideFlowComplete(fare: fare.totalFare)));
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
