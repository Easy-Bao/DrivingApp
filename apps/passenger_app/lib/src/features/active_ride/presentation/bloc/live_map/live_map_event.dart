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

final class const DrawDriverToRiderRouteEvent({
  required final double riderLat,
  required final double riderLng,
  required final double driverLat,
  required final double driverLng,
}) extends LiveMapEvent;

final class const AddMapMarkerEvent({
  required final double lat,
  required final double lng,
  final String? label,
  final bool isOrigin = false,
  final void Function()? onTap,
}) extends LiveMapEvent;

final class const ClearMapAnnotationsEvent() extends LiveMapEvent;

final class const FitMapToCoordinatesEvent({
  required final List<LatLng> coordinates,
  final double? maxZoom,
}) extends LiveMapEvent;

final class const DispatchTelemetryLocationEvent({
  required final double lat,
  required final double lng,
  required final String rideId,
}) extends LiveMapEvent;
