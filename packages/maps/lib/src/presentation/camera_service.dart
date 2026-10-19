import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class const LatLng(this.latitude, this.longitude) {
  final double latitude;
  final double longitude;
}

class const AppMapController(this.native) {
  final mapbox.MapboxMap native;
}

class MapCameraService._() {
  static const _defaultFitBoundsMaxZoom = 15.5;

  static Future<void> moveCamera(
    AppMapController controller,
    double latitude,
    double longitude, {
    double? zoom,
    bool animate = true,
  }) => traceTimelineStage('maps.camera.move', () async {
    final camera = mapbox.CameraOptions(
      center: mapbox.Point(coordinates: mapbox.Position(longitude, latitude)),
      zoom: zoom,
    );

    if (animate) {
      await traceTimelineStage(
        'maps.camera.fly_to',
        () => controller.native.flyTo(
          camera,
          mapbox.MapAnimationOptions(duration: 800),
        ),
      );
    } else {
      await traceTimelineStage(
        'maps.camera.set',
        () => controller.native.setCamera(camera),
      );
    }
  });

  static Future<LatLng> getCameraCenter(AppMapController controller) =>
      traceTimelineStage('maps.camera.get_center', () async {
        final camera = await controller.native.getCameraState();
        final center = camera.center;
        return LatLng(
          center.coordinates.lat.toDouble(),
          center.coordinates.lng.toDouble(),
        );
      });

  static Future<Offset> getScreenCoordinate(
    AppMapController controller,
    double latitude,
    double longitude,
  ) => traceTimelineStage('maps.camera.project_coordinate', () async {
    final coordinate = await controller.native.pixelForCoordinate(
      mapbox.Point(coordinates: mapbox.Position(longitude, latitude)),
    );
    return Offset(coordinate.x, coordinate.y);
  });

  static Future<void> fitBounds(
    AppMapController controller,
    List<LatLng> points, {
    double padding = 80.0,
    double? maxZoom,
  }) => traceTimelineStage('maps.camera.fit_bounds', () async {
    if (points.isEmpty) return;

    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;

    for (final point in points) {
      minLatitude = math.min(minLatitude, point.latitude);
      maxLatitude = math.max(maxLatitude, point.latitude);
      minLongitude = math.min(minLongitude, point.longitude);
      maxLongitude = math.max(maxLongitude, point.longitude);
    }

    final bounds = mapbox.CoordinateBounds(
      southwest: mapbox.Point(
        coordinates: mapbox.Position(minLongitude, minLatitude),
      ),
      northeast: mapbox.Point(
        coordinates: mapbox.Position(maxLongitude, maxLatitude),
      ),
      infiniteBounds: false,
    );

    final camera = await traceTimelineStage(
      'maps.camera.calculate_bounds',
      () => controller.native.cameraForCoordinateBounds(
        bounds,
        mapbox.MbxEdgeInsets(
          top: padding,
          left: padding,
          bottom: padding + 100,
          right: padding,
        ),
        null,
        null,
        null,
        null,
      ),
    );

    final cameraToShow = _limitZoom(
      camera,
      maxZoom ?? _defaultFitBoundsMaxZoom,
    );

    await traceTimelineStage(
      'maps.camera.fly_to_bounds',
      () => controller.native.flyTo(
        cameraToShow,
        mapbox.MapAnimationOptions(duration: 1000),
      ),
    );
  });

  static mapbox.CameraOptions _limitZoom(
    mapbox.CameraOptions camera,
    double? maxZoom,
  ) {
    final zoom = camera.zoom;
    if (maxZoom == null || zoom == null || zoom <= maxZoom) return camera;

    return mapbox.CameraOptions(
      center: camera.center,
      padding: camera.padding,
      anchor: camera.anchor,
      zoom: maxZoom,
      bearing: camera.bearing,
      pitch: camera.pitch,
    );
  }
}
