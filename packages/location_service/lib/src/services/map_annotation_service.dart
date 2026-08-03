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
        image: await _createMarkerImage(Color(markerColor), label: label),
        iconAnchor: mapbox.IconAnchor.BOTTOM,
        // Keep information cards legible while the map camera changes zoom.
        iconSize: label == null ? (isOrigin ? 0.8 : 0.9) : 1.0,
        symbolSortKey: 20,
      ),
    );
    return annotationManager;
  }

  static Future<Uint8List> _createMarkerImage(
    Color color, {
    String? label,
  }) async {
    if (label == null || label.trim().isEmpty) {
      return _createPinImage(color);
    }

    const width = 360.0;
    const height = 104.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final background = Paint()..color = Colors.white;
    final shadow = Paint()..color = const Color(0x22000000);
    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 8, width - 16, 78),
      const Radius.circular(22),
    );
    canvas.drawRRect(cardRect.shift(const Offset(0, 6)), shadow);
    canvas.drawRRect(cardRect, background);
    final pointer = Path()
      ..moveTo(width / 2 - 14, 84)
      ..lineTo(width / 2, height - 4)
      ..lineTo(width / 2 + 14, 84)
      ..close();
    canvas.drawPath(pointer, background);

    canvas.drawCircle(const Offset(48, 47), 20, Paint()..color = color);
    canvas.drawCircle(const Offset(48, 47), 8, Paint()..color = Colors.white);

    final lines = label.split('\n');
    _drawLabelText(
      canvas,
      lines.first,
      const Offset(82, 25),
      width: 250,
      fontSize: 23,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1A1D20),
    );
    if (lines.length > 1) {
      _drawLabelText(
        canvas,
        lines.skip(1).join(' '),
        const Offset(82, 55),
        width: 250,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: const Color(0x991A1D20),
      );
    }

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  static void _drawLabelText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double width,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1, ellipsis: '…'))
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          )
          ..addText(text);
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(paragraph, offset);
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
