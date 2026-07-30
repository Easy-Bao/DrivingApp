import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/ride_flow_state.freezed.dart';

@freezed
sealed class RideFlowState with _$RideFlowState {
  const factory RideFlowState.initial() = RideFlowInitial;
  const factory RideFlowState.enRoutePickup({
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
  }) = RideFlowEnRoutePickup;
  const factory RideFlowState.waitingPassenger({
    required String passengerName,
    required int waitTimeSeconds,
  }) = RideFlowWaitingPassenger;
  const factory RideFlowState.inTransit({
    required String passengerName,
    required double destLat,
    required double destLng,
    required double distanceKm,
  }) = RideFlowInTransit;
  const factory RideFlowState.complete({
    required double fare,
  }) = RideFlowComplete;
  const factory RideFlowState.error(String message) = RideFlowError;
}
