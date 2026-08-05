import 'package:equatable/equatable.dart';

sealed class RideFlowState extends Equatable {
  const RideFlowState();

  @override
  List<Object?> get props => [];
}

class RideFlowInitial extends RideFlowState {
  const RideFlowInitial();
}

class RideFlowEnRoutePickup extends RideFlowState {
  final String passengerName;
  final double? pickupLat;
  final double? pickupLng;
  final double? destLat;
  final double? destLng;

  const RideFlowEnRoutePickup({
    required this.passengerName,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
  });

  @override
  List<Object?> get props => [
    passengerName,
    pickupLat,
    pickupLng,
    destLat,
    destLng,
  ];
}

class RideFlowWaitingPassenger extends RideFlowState {
  final String passengerName;
  final int waitTimeSeconds;
  final double? pickupLat;
  final double? pickupLng;
  final double? destLat;
  final double? destLng;

  const RideFlowWaitingPassenger({
    required this.passengerName,
    required this.waitTimeSeconds,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
  });

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

class RideFlowInTransit extends RideFlowState {
  final String passengerName;
  final double? destLat;
  final double? destLng;
  final double? distanceKm;
  final double? passengerLat;
  final double? passengerLng;

  const RideFlowInTransit({
    required this.passengerName,
    this.destLat,
    this.destLng,
    this.distanceKm,
    this.passengerLat,
    this.passengerLng,
  });

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

class RideFlowComplete extends RideFlowState {
  final double fare;

  const RideFlowComplete({required this.fare});

  @override
  List<Object?> get props => [fare];
}

class RideFlowError extends RideFlowState {
  final String message;

  const RideFlowError(this.message);

  @override
  List<Object?> get props => [message];
}
