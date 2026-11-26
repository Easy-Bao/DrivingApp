import 'dart:async';

import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart' hide Route;

class const RideDetailsMap({
  super.key,
  required this.pickupLatitude,
  required this.pickupLongitude,
  required this.dropoffLatitude,
  required this.dropoffLongitude,
}) extends StatefulWidget {
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;

  @override
  State<RideDetailsMap> createState() => _RideDetailsMapState();
}

class _RideDetailsMapState extends State<RideDetailsMap> {
  AppMapController? _controller;
  Widget? _mapView;
  MapPointAnnotationManager? _pickupMarkerManager;
  MapPointAnnotationManager? _dropoffMarkerManager;
  MapPolylineAnnotationManager? _routeLineManager;

  late final Future<Route?> _route = MapProvider.getRoute(
    widget.pickupLatitude,
    widget.pickupLongitude,
    widget.dropoffLatitude,
    widget.dropoffLongitude,
  );

  @override
  void dispose() {
    _clearAnnotations();
    _controller = null;
    super.dispose();
  }

  void _clearAnnotations() {
    for (final manager in <MapBaseAnnotationManager?>[
      _routeLineManager,
      _pickupMarkerManager,
      _dropoffMarkerManager,
    ]) {
      unawaited(MapProvider.clearAnnotations(manager));
    }
    _routeLineManager = null;
    _pickupMarkerManager = null;
    _dropoffMarkerManager = null;
  }

  Future<void> _renderTrip() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final routeColor = Theme.of(context).colorScheme.onSurface;
    final stops = [
      LatLng(widget.pickupLatitude, widget.pickupLongitude),
      LatLng(widget.dropoffLatitude, widget.dropoffLongitude),
    ];

    try {
      // Fit only after the native map is loaded and has its preview size.
      await MapProvider.fitBounds(
        controller,
        stops,
        viewportPadding: const EdgeInsets.all(28),
      );
      if (!mounted || controller != _controller) return;
      _clearAnnotations();

      final markers = await Future.wait([
        MapProvider.addMarker(
          controller,
          widget.pickupLatitude,
          widget.pickupLongitude,
          isOrigin: true,
          color: TripMapMarkerStyle.ownLocation,
        ),
        MapProvider.addMarker(
          controller,
          widget.dropoffLatitude,
          widget.dropoffLongitude,
          color: TripMapMarkerStyle.tripLocation,
        ),
      ]);
      if (!mounted || controller != _controller) {
        for (final manager in markers) {
          unawaited(MapProvider.clearAnnotations(manager));
        }
        return;
      }
      _pickupMarkerManager = markers[0];
      _dropoffMarkerManager = markers[1];

      final route = await _route;
      if (!mounted ||
          controller != _controller ||
          route == null ||
          !route.hasGeometry) {
        return;
      }
      final polylineManager = await MapProvider.addPolylineBuffer(
        controller,
        route.coordinateBuffer,
        color: routeColor,
        width: 4.5,
      );
      if (!mounted || controller != _controller) {
        unawaited(MapProvider.clearAnnotations(polylineManager));
        return;
      }
      _routeLineManager = polylineManager;
      await MapProvider.fitBounds(controller, [
        ...stops,
        for (final point in route.validPolylinePoints)
          LatLng(point[1], point[0]),
      ], viewportPadding: const EdgeInsets.all(28));
    } catch (_) {
      debugPrint('Ride details route preview is unavailable.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _mapView ??= MapProvider.buildMapView(
      latitude: (widget.pickupLatitude + widget.dropoffLatitude) / 2,
      longitude: (widget.pickupLongitude + widget.dropoffLongitude) / 2,
      zoom: 13,
      interactive: false,
      onMapCreated: (controller) {
        _clearAnnotations();
        _controller = controller;
      },
      onMapLoaded: () => unawaited(_renderTrip()),
    );
  }
}
