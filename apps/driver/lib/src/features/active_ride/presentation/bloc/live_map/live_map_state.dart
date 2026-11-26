part of 'live_map_bloc.dart';

sealed class LiveMapState extends Equatable {
  const LiveMapState();

  @override
  List<Object?> get props => const [];
}

final class LiveMapInitial extends LiveMapState {
  const LiveMapInitial();
}

final class LiveMapReady extends LiveMapState {
  const LiveMapReady(this.currentLatitude, this.currentLongitude);

  final double currentLatitude;
  final double currentLongitude;

  @override
  List<Object?> get props => [currentLatitude, currentLongitude];
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

  @override
  List<Object?> get props => [
    driverLatitude,
    driverLongitude,
    passengerLatitude,
    passengerLongitude,
  ];
}
