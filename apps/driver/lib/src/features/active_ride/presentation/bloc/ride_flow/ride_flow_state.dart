import 'package:equatable/equatable.dart';

sealed class const RideFlowState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const RideFlowInitial() extends RideFlowState;

final class const RideFlowNavigatingToPickup({
  required final String passengerName,
  final double? pickupLat,
  final double? pickupLng,
  final double? destLat,
  final double? destLng,
}) extends RideFlowState {
  @override
  List<Object?> get props => [
    passengerName,
    pickupLat,
    pickupLng,
    destLat,
    destLng,
  ];
}

final class const RideFlowWaitingPassenger({
  required final String passengerName,
  required final int waitTimeSeconds,
  final double? pickupLat,
  final double? pickupLng,
  final double? destLat,
  final double? destLng,
}) extends RideFlowState {
  @override
  List<Object?> get props => [
    passengerName,
    waitTimeSeconds,
    pickupLat,
    pickupLng,
    destLat,
    destLng,
  ];
}

final class const RideFlowInTransit({
  required final String passengerName,
  final double? destLat,
  final double? destLng,
  final double? distanceKm,
  final double? passengerLat,
  final double? passengerLng,
}) extends RideFlowState {
  @override
  List<Object?> get props => [
    passengerName,
    destLat,
    destLng,
    distanceKm,
    passengerLat,
    passengerLng,
  ];
}

final class const RideFlowComplete({required final double fare})
    extends RideFlowState {
  @override
  List<Object?> get props => [fare];
}

final class const RideFlowError(final String message) extends RideFlowState {
  @override
  List<Object?> get props => [message];
}
