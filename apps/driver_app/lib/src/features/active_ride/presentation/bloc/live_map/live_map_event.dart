part of 'live_map_bloc.dart';

abstract class LiveMapEvent {
  const LiveMapEvent();
}

final class const InitializeMapEvent({
  required final AppMapController controller,
  required final double defaultLat,
  required final double defaultLng,
  required final Color routeColor,
}) extends LiveMapEvent;

final class const UpdateLocationsAndDrawRouteEvent({
  required final double driverLat,
  required final double driverLng,
  required final double? passengerLat,
  required final double? passengerLng,
  final double? routeTargetLat,
  final double? routeTargetLng,
}) extends LiveMapEvent;

final class const ClearMapEvent() extends LiveMapEvent;

final class const DispatchTelemetryLocationEvent({
  required final double lat,
  required final double lng,
}) extends LiveMapEvent;
