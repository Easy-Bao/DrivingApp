import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:driver_app/features/driver/presentation/bloc/ride/ride_flow_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Manages the sequential ride lifecycle: initial → en-route → waiting → in-transit → complete.
class RideFlowCubit extends Cubit<RideFlowState> {
  final RideRepository _repository;
  Timer? _waitTimer;
  int _elapsedWaitTime = 0;

  RideFlowCubit({required RideRepository repository})
    : _repository = repository,
      super(RideFlowInitial());

  /// Driver accepted a ride request — begin navigating to pickup.
  void acceptRide({
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
  }) {
    emit(
      RideFlowEnRoutePickup(
        passengerName: passengerName,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
      ),
    );
  }

  // Driver has arrived at the pickup location — start waiting timer.
  void arriveAtPickup(String passengerName) {
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;
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
  void startRide({
    required String passengerName,
    required double destLat,
    required double destLng,
    required double distanceKm,
  }) {
    _waitTimer?.cancel();
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
    try {
      final fareResult = await _repository.getFare(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
      emit(RideFlowComplete(fare: fareResult.totalFare));
    } catch (_) {
      // Fallback to minimum fare on error — never leave the driver on a loading screen.
      emit(const RideFlowComplete(fare: 50.0));
    }
  }

  // Resets the ride flow back to idle.
  void reset() {
    _waitTimer?.cancel();
    emit(RideFlowInitial());
  }

  @override
  Future<void> close() {
    _waitTimer?.cancel();
    return super.close();
  }
}
