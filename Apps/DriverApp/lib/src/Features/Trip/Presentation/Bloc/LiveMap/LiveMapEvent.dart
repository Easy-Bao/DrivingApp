import 'package:location_service/location_service.dart';

abstract class LiveMapEvent {
  const LiveMapEvent();
}

class InitializeMapEvent extends LiveMapEvent {
  final AppMapController controller;
  final double defaultLat;
  final double defaultLng;

  const InitializeMapEvent({
    required this.controller,
    required this.defaultLat,
    required this.defaultLng,
  });
}

class UpdateLocationsAndDrawRouteEvent extends LiveMapEvent {
  final double driverLat;
  final double driverLng;
  final double passengerLat;
  final double passengerLng;

  const UpdateLocationsAndDrawRouteEvent({
    required this.driverLat,
    required this.driverLng,
    required this.passengerLat,
    required this.passengerLng,
  });
}

class ClearMapEvent extends LiveMapEvent {
  const ClearMapEvent();
}

class DispatchTelemetryLocationEvent extends LiveMapEvent {
  final double lat;
  final double lng;

  const DispatchTelemetryLocationEvent({required this.lat, required this.lng});
}
