import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BaoRide/features/driver/data/repositories/ride_repository.dart';
import 'ride_flow_state.dart';

class RideFlowCubit extends Cubit<RideFlowState> {
  final RideRepository _rideRepository;
  Timer? _waitTimer;
  int _elapsedWaitTime = 0;

  RideFlowCubit({required RideRepository rideRepository})
      : _rideRepository = rideRepository,
        super(RideFlowInitial());

  void acceptRide({
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
  }) {
    emit(RideFlowEnRoutePickup(
      passengerName: passengerName,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
    ));
  }

  void arriveAtPickup(String passengerName) {
    _waitTimer?.cancel();
    _elapsedWaitTime = 0;
    emit(RideFlowWaitingPassenger(
      passengerName: passengerName,
      waitTimeSeconds: 0,
    ));
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) return;
      _elapsedWaitTime++;
      emit(RideFlowWaitingPassenger(
        passengerName: passengerName,
        waitTimeSeconds: _elapsedWaitTime,
      ));
    });
  }

  void startRide({
    required String passengerName,
    required double destLat,
    required double destLng,
    required double distanceKm,
  }) {
    _waitTimer?.cancel();
    emit(RideFlowInTransit(
      passengerName: passengerName,
      destLat: destLat,
      destLng: destLng,
      distanceKm: distanceKm,
    ));
  }

  Future<void> endRide({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    _waitTimer?.cancel();
    try {
      final fareResult = await _rideRepository.getFare(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
      emit(RideFlowComplete(fare: fareResult.totalFare));
    } catch (e) {
      emit(const RideFlowComplete(fare: 50.0)); // Fallback
    }
  }

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
