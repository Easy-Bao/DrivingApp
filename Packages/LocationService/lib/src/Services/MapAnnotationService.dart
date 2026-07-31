import 'package:flutter/material.dart';
import 'package:location_service/src/Services/MapCameraService.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class MapAnnotationService {
  MapAnnotationService._();

  static Future<dynamic> addMarker(
    AppMapController controller,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
  }) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final annotationManager = await mapCtrl.annotations
        .createCircleAnnotationManager();

    final markerColor = color != null
        ? color.toARGB32()
        : (isOrigin ? 0xFF222222 : 0xFF607B8B);

    await annotationManager.create(
      mapbox.CircleAnnotationOptions(
        geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
        circleRadius: isOrigin ? 8.0 : 10.0,
        circleColor: markerColor,
        circleStrokeWidth: 3.0,
        circleStrokeColor: 0xFFFFFFFF,
      ),
    );
    return annotationManager;
  }

  static Future<void> addPolyline(
    AppMapController controller,
    List<List<double>> points, {
    Color color = const Color(0xFF222222),
    double width = 4.0,
  }) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final annotationManager = await mapCtrl.annotations
        .createPolylineAnnotationManager();

    final coordinates = points.map((p) => mapbox.Position(p[0], p[1])).toList();

    await annotationManager.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: coordinates),
        lineWidth: width,
        lineColor: color.toARGB32(),
        lineJoin: mapbox.LineJoin.ROUND,
      ),
    );
  }

  static Future<dynamic> addAnimatedPolylineSegment(
    AppMapController controller,
    List<List<double>> points, {
    Color color = const Color(0xFF222222),
    double width = 5.0,
  }) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final annotationManager = await mapCtrl.annotations
        .createPolylineAnnotationManager();

    final coordinates = points.map((p) => mapbox.Position(p[0], p[1])).toList();

    await annotationManager.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: coordinates),
        lineWidth: width,
        lineColor: color.toARGB32(),
        lineJoin: mapbox.LineJoin.ROUND,
      ),
    );

    return annotationManager;
  }

  static Future<void> clearAnnotations(dynamic manager) async {
    if (manager != null) {
      try {
        await manager.deleteAll();
      } catch (error) {
        debugPrint('Error clearing annotations: $error');
      }
    }
  }
}
