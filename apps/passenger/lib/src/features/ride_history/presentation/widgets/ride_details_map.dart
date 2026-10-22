import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:maps/maps.dart';

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
  late final Future<Route?> _route = MapProvider.getRoute(
    widget.pickupLatitude,
    widget.pickupLongitude,
    widget.dropoffLatitude,
    widget.dropoffLongitude,
  );

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
      await Future.wait([
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

      final route = await _route;
      if (!mounted ||
          controller != _controller ||
          route == null ||
          !route.hasGeometry) {
        return;
      }
      await MapProvider.addPolylineBuffer(
        controller,
        route.coordinateBuffer,
        color: routeColor,
        width: 4.5,
      );
      if (!mounted || controller != _controller) return;
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
      onMapCreated: (controller) => _controller = controller,
      onMapLoaded: () => unawaited(_renderTrip()),
    );
  }
}
