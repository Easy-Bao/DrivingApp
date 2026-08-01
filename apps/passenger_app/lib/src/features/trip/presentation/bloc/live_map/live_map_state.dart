abstract class LiveMapState {
  const LiveMapState();
}

class LiveMapInitial extends LiveMapState {}

class LiveMapReady extends LiveMapState {
  final double currentLat;
  final double currentLng;

  const LiveMapReady(this.currentLat, this.currentLng);
}

class LiveMapRouteDrawn extends LiveMapState {
  final double riderLat;
  final double riderLng;
  final double driverLat;
  final double driverLng;

  const LiveMapRouteDrawn({
    required this.riderLat,
    required this.riderLng,
    required this.driverLat,
    required this.driverLng,
  });
}
