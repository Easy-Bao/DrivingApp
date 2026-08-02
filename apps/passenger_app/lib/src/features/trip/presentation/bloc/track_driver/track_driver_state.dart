import 'package:equatable/equatable.dart';

sealed class TrackDriverState extends Equatable {
  const TrackDriverState();

  @override
  List<Object?> get props => [];
}

class TrackDriverInitial extends TrackDriverState {
  const TrackDriverInitial();
}

class TrackDriverInProgress extends TrackDriverState {
  final double driverLat;
  final double driverLng;
  final double progress;
  final String eta;
  final String driverName;
  final String vehiclePlate;
  final String vehicleType;
  final List<List<double>>? routePoints;

  const TrackDriverInProgress({
    required this.driverLat,
    required this.driverLng,
    required this.progress,
    required this.eta,
    required this.driverName,
    required this.vehiclePlate,
    required this.vehicleType,
    this.routePoints,
  });

  @override
  List<Object?> get props => [
    driverLat,
    driverLng,
    progress,
    eta,
    driverName,
    vehiclePlate,
    vehicleType,
    routePoints,
  ];
}

class TrackDriverCompleted extends TrackDriverState {
  final String driverId;
  final String driverName;

  const TrackDriverCompleted({
    required this.driverId,
    required this.driverName,
  });

  @override
  List<Object?> get props => [driverId, driverName];
}

class TrackDriverCanceled extends TrackDriverState {
  const TrackDriverCanceled();
}
