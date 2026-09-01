import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class AppMapController {
  final mapbox.MapboxMap native;

  const AppMapController(this.native);
}

class MapCameraService {
  MapCameraService._();

  static Future<void> moveCamera(
    AppMapController controller,
    double lat,
    double lng, {
    double? zoom,
    bool animate = true,
  }) async {
    final camera = mapbox.CameraOptions(
      center: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
      zoom: zoom,
    );

    if (animate) {
      await controller.native.flyTo(
        camera,
        mapbox.MapAnimationOptions(duration: 800),
      );
    } else {
      await controller.native.setCamera(camera);
    }
  }

  static Future<LatLng> getCameraCenter(AppMapController controller) async {
    final camera = await controller.native.getCameraState();
    final center = camera.center;
    return LatLng(
      center.coordinates.lat.toDouble(),
      center.coordinates.lng.toDouble(),
    );
  }

  static Future<Offset> getScreenCoordinate(
    AppMapController controller,
    double lat,
    double lng,
  ) async {
    final coordinate = await controller.native.pixelForCoordinate(
      mapbox.Point(coordinates: mapbox.Position(lng, lat)),
    );
    return Offset(coordinate.x, coordinate.y);
  }

  static Future<void> fitBounds(
    AppMapController controller,
    List<LatLng> points, {
    double padding = 80.0,
    double? maxZoom,
  }) async {
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final bounds = mapbox.CoordinateBounds(
      southwest: mapbox.Point(coordinates: mapbox.Position(minLng, minLat)),
      northeast: mapbox.Point(coordinates: mapbox.Position(maxLng, maxLat)),
      infiniteBounds: false,
    );

    final camera = await controller.native.cameraForCoordinateBounds(
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
    );

    final cameraToShow = _limitZoom(camera, maxZoom);

    await controller.native.flyTo(
      cameraToShow,
      mapbox.MapAnimationOptions(duration: 1000),
    );
  }

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
