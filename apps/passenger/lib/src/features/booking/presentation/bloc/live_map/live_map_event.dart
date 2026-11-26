part of 'live_map_bloc.dart';

sealed class const LiveMapEvent() {}

final class const InitializeMapEvent({
  required final AppMapController controller,
  required final double defaultLat,
  required final double defaultLng,
}) extends LiveMapEvent;

final class const AddMapMarkerEvent({
  required final double lat,
  required final double lng,
  final String? label,
  final Color? color,
  final bool isOrigin = false,
  final void Function()? onTap,
}) extends LiveMapEvent;

final class const ClearMapAnnotationsEvent() extends LiveMapEvent;

final class const ReplaceMapMarkersEvent({
  required final List<AddMapMarkerEvent> markers,
}) extends LiveMapEvent;

final class const FitMapToCoordinatesEvent({
  required final List<LatLng> coordinates,
  final double? maxZoom,
}) extends LiveMapEvent;
