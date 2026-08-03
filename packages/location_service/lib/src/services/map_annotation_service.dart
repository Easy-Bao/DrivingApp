import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:location_service/src/services/map_camera_service.dart';
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
        .createPointAnnotationManager();

    final markerColor = color != null
        ? color.toARGB32()
        : (isOrigin ? 0xFF222222 : 0xFF607B8B);

    await annotationManager.create(
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
        image: await _createPinImage(Color(markerColor)),
        iconAnchor: mapbox.IconAnchor.BOTTOM,
        iconSize: isOrigin ? 0.8 : 0.9,
        symbolSortKey: 20,
      ),
    );
    return annotationManager;
  }

  static Future<Uint8List> _createPinImage(Color color) async {
    const size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final pin = Path()
      ..moveTo(size / 2, size - 2)
      ..cubicTo(10, 39, 8, 32, 8, 24)
      ..cubicTo(8, 11, 18, 2, size / 2, 2)
      ..cubicTo(46, 2, 56, 11, 56, 24)
      ..cubicTo(56, 32, 54, 39, size / 2, size - 2)
      ..close();
    canvas.drawPath(pin, paint);
    canvas.drawPath(pin, outlinePaint);
    canvas.drawCircle(
      const Offset(size / 2, 24),
      8,
      Paint()..color = Colors.white,
    );
    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
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
