part of 'live_map_bloc.dart';

sealed class LiveMapState {
  const LiveMapState();
}

final class LiveMapInitial extends LiveMapState {}

final class LiveMapReady extends LiveMapState {
  const LiveMapReady(this.currentLatitude, this.currentLongitude);

  final double currentLatitude;
  final double currentLongitude;
}

final class LiveMapRouteUpdated extends LiveMapState {
  const LiveMapRouteUpdated({
    required this.driverLatitude,
    required this.driverLongitude,
    required this.passengerLatitude,
    required this.passengerLongitude,
  });

  final double driverLatitude;
  final double driverLongitude;
  final double? passengerLatitude;
  final double? passengerLongitude;
}
