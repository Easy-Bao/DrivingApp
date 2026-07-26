import 'dart:math' as math;
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

  static Future<LatLng> getCameraCenter(AppMapController controller) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final camera = await mapCtrl.getCameraState();
    final center = camera.center;
    return LatLng(
      center.coordinates.lat.toDouble(),
      center.coordinates.lng.toDouble(),
    );
  }

  static Future<void> fitBounds(
    AppMapController controller,
    List<LatLng> points, {
    double padding = 80.0,
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

    await mapCtrl.flyTo(camera, mapbox.MapAnimationOptions(duration: 1000));
  }
}
