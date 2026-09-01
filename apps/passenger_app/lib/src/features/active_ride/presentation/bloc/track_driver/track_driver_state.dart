import 'package:passenger_app/src/features/active_ride/active_ride.dart';
import 'package:equatable/equatable.dart';

sealed class const TrackDriverState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const TrackDriverInitial() extends TrackDriverState;

final class const TrackDriverInProgress({
  required final double driverLat,
  required final double driverLng,
  required final double progress,
  required final String eta,
  required final String driverName,
  required final String vehiclePlate,
  required final String vehicleType,
  final List<List<double>>? routePoints,
  final RideStatus status = RideStatus.accepted,
}) extends TrackDriverState {
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
    status,
  ];
}

final class const TrackDriverCompleted({
  required final String driverId,
  required final String driverName,
}) extends TrackDriverState {
  @override
  List<Object?> get props => [driverId, driverName];
}

final class const TrackDriverCanceled() extends TrackDriverState;
