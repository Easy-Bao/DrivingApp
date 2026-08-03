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
  final double pickupLat;
  final double pickupLng;

  const RideFlowEnRoutePickup({
    required this.passengerName,
    this.pickupLat = 0,
    this.pickupLng = 0,
  });

  @override
  List<Object?> get props => [passengerName, pickupLat, pickupLng];
}

class RideFlowWaitingPassenger extends RideFlowState {
  final String passengerName;
  final int waitTimeSeconds;
  final double pickupLat;
  final double pickupLng;

  const RideFlowWaitingPassenger({
    required this.passengerName,
    required this.waitTimeSeconds,
    this.pickupLat = 0,
    this.pickupLng = 0,
  });

  @override
  List<Object?> get props => [
    passengerName,
    waitTimeSeconds,
    pickupLat,
    pickupLng,
  ];
}

class RideFlowInTransit extends RideFlowState {
  final String passengerName;
  final double destLat;
  final double destLng;
  final double distanceKm;
  final double passengerLat;
  final double passengerLng;

  const RideFlowInTransit({
    required this.passengerName,
    required this.destLat,
    required this.destLng,
    required this.distanceKm,
    this.passengerLat = 0,
    this.passengerLng = 0,
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
