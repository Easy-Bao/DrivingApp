import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class AppMapController {
  final dynamic _native;
  AppMapController(this._native);
  dynamic get native => _native;
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
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final camera = mapbox.CameraOptions(
      center: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
      zoom: zoom,
    );

    if (animate) {
      await mapCtrl.flyTo(camera, mapbox.MapAnimationOptions(duration: 800));
    } else {
      await mapCtrl.setCamera(camera);
    }
  }

  static Future<void> zoomIn(AppMapController controller) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final cameraState = await mapCtrl.getCameraState();
    final currentZoom = cameraState.zoom;
    final targetZoom = (currentZoom + 1.0).clamp(2.0, 20.0);
    await mapCtrl.flyTo(
      mapbox.CameraOptions(zoom: targetZoom),
      mapbox.MapAnimationOptions(duration: 350),
    );
  }

  static Future<void> zoomOut(AppMapController controller) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final cameraState = await mapCtrl.getCameraState();
    final currentZoom = cameraState.zoom;
    final targetZoom = (currentZoom - 1.0).clamp(2.0, 20.0);
    await mapCtrl.flyTo(
      mapbox.CameraOptions(zoom: targetZoom),
      mapbox.MapAnimationOptions(duration: 350),
    );
  }

  static Future<LatLng> getCameraCenter(AppMapController controller) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final camera = await mapCtrl.getCameraState();
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
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final coordinate = await mapCtrl.pixelForCoordinate(
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

    final mapCtrl = controller.native as mapbox.MapboxMap;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    final bounds = mapbox.CoordinateBounds(
      southwest: mapbox.Point(coordinates: mapbox.Position(minLng, minLat)),
      northeast: mapbox.Point(coordinates: mapbox.Position(maxLng, maxLat)),
      infiniteBounds: false,
    );

    final camera = await mapCtrl.cameraForCoordinateBounds(
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

    final zoom = camera.zoom;
    final cameraToShow = maxZoom != null && zoom != null && zoom > maxZoom
        ? mapbox.CameraOptions(
            center: camera.center,
            padding: camera.padding,
            anchor: camera.anchor,
            zoom: maxZoom,
            bearing: camera.bearing,
            pitch: camera.pitch,
          )
        : camera;

    await mapCtrl.flyTo(
      cameraToShow,
      mapbox.MapAnimationOptions(duration: 1000),
    );
  }
}
