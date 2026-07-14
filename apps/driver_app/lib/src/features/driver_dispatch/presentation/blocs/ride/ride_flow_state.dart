import 'package:equatable/equatable.dart';

/// Ride Flow State component defining application state or layout.
abstract class RideFlowState extends Equatable {
  const RideFlowState();

  @override
  List<Object?> get props => [];
}

class RideFlowInitial extends RideFlowState {}

class RideFlowEnRoutePickup extends RideFlowState {
  final String passengerName;
  final double pickupLat;
  final double pickupLng;

  const RideFlowEnRoutePickup({
    required this.passengerName,
    required this.pickupLat,
    required this.pickupLng,
  });

  @override
  List<Object?> get props => [passengerName, pickupLat, pickupLng];
}

class RideFlowWaitingPassenger extends RideFlowState {
  final String passengerName;
  final int waitTimeSeconds;

  const RideFlowWaitingPassenger({
    required this.passengerName,
    required this.waitTimeSeconds,
  });

  @override
  List<Object?> get props => [passengerName, waitTimeSeconds];
}

class RideFlowInTransit extends RideFlowState {
  final String passengerName;
  final double destLat;
  final double destLng;
  final double distanceKm;

  const RideFlowInTransit({
    required this.passengerName,
    required this.destLat,
    required this.destLng,
    required this.distanceKm,
  });

  @override
  List<Object?> get props => [passengerName, destLat, destLng, distanceKm];
}

class RideFlowComplete extends RideFlowState {
  final double fare;

  const RideFlowComplete({required this.fare});

  @override
  List<Object?> get props => [fare];
}
