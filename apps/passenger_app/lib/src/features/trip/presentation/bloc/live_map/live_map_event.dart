import 'package:shared_core/shared_core.dart';

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

class DrawDriverToRiderRouteEvent extends LiveMapEvent {
  final double riderLat;
  final double riderLng;
  final double driverLat;
  final double driverLng;

  const DrawDriverToRiderRouteEvent({
    required this.riderLat,
    required this.riderLng,
    required this.driverLat,
    required this.driverLng,
  });
}

class AddMapMarkerEvent extends LiveMapEvent {
  final double lat;
  final double lng;
  final String label;
  final bool isOrigin;
  final void Function()? onTap;

  const AddMapMarkerEvent({
    required this.lat,
    required this.lng,
    required this.label,
    this.isOrigin = false,
    this.onTap,
  });
}

class ClearMapAnnotationsEvent extends LiveMapEvent {
  const ClearMapAnnotationsEvent();
}

class FitMapToCoordinatesEvent extends LiveMapEvent {
  final List<LatLng> coordinates;
  final double? maxZoom;

  const FitMapToCoordinatesEvent({required this.coordinates, this.maxZoom});
}

class DispatchTelemetryLocationEvent extends LiveMapEvent {
  final double lat;
  final double lng;
  final String rideId;

  const DispatchTelemetryLocationEvent({
    required this.lat,
    required this.lng,
    required this.rideId,
  });
}
