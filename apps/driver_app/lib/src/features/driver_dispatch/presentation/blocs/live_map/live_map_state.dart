/// Live Map State component defining application state or layout.
abstract class LiveMapState {
  const LiveMapState();
}

class LiveMapInitial extends LiveMapState {}

class LiveMapReady extends LiveMapState {
  final double currentLat;
  final double currentLng;

  const LiveMapReady(this.currentLat, this.currentLng);
}

class LiveMapRouteUpdated extends LiveMapState {
  final double driverLat;
  final double driverLng;
  final double passengerLat;
  final double passengerLng;

  const LiveMapRouteUpdated({
    required this.driverLat,
    required this.driverLng,
    required this.passengerLat,
    required this.passengerLng,
  });
}
