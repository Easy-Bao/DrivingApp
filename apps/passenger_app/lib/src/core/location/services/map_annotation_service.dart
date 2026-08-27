import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:passenger_app/src/core/location/services/map_camera_service.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class TripMapMarkerStyle {
  TripMapMarkerStyle._();

  static const double pinIconSize = 1.22;
  static const Color ownLocation = AppTheme.primaryColor;
  static const Color tripLocation = AppTheme.complete;

  static Color colorFor({required bool isOrigin}) {
    return isOrigin ? ownLocation : tripLocation;
  }
}

class MapAnnotationService {
  MapAnnotationService._();

  static Future<mapbox.PointAnnotationManager> addMarker(
    AppMapController controller,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    VoidCallback? onTap,
  }) async {
    final mapCtrl = controller.native;
    final annotationManager = await mapCtrl.annotations
        .createPointAnnotationManager();

    await annotationManager.create(
      await _markerOptions(
        lat,
        lng,
        label: label,
        isOrigin: isOrigin,
        color: color,
      ),
    );
    if (onTap != null) {
      annotationManager.tapEvents(onTap: (_) => onTap());
    }
    return annotationManager;
  }

  static Future<void> replaceMarker(
    mapbox.PointAnnotationManager annotationManager,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    bool animate = false,
  }) async {
    final options = await _markerOptions(
      lat,
      lng,
      label: label,
      isOrigin: isOrigin,
      color: color,
    );
    final annotations = await annotationManager.getAnnotations();
    if (annotations.isEmpty) {
      await annotationManager.create(options);
      return;
    }

    final annotation = annotations.first;
    annotation.image = options.image;
    annotation.iconAnchor = options.iconAnchor;
    annotation.iconSize = options.iconSize;
    annotation.symbolSortKey = options.symbolSortKey;
    if (animate) {
      await _animateMarker(
        annotationManager,
        annotation,
        targetLat: lat,
        targetLng: lng,
      );
    } else {
      annotation.geometry = options.geometry;
      await annotationManager.update(annotation);
    }
    if (annotations.length > 1) {
      await annotationManager.deleteMulti(annotations.skip(1).toList());
    }
  }

  static Future<void> _animateMarker(
    mapbox.PointAnnotationManager annotationManager,
    mapbox.PointAnnotation annotation, {
    required double targetLat,
    required double targetLng,
  }) async {
    final startLat = annotation.geometry.coordinates.lat.toDouble();
    final startLng = annotation.geometry.coordinates.lng.toDouble();
    const frameCount = 18;
    for (var frame = 1; frame <= frameCount; frame++) {
      final progress = Curves.easeInOut.transform(frame / frameCount);
      annotation.geometry = mapbox.Point(
        coordinates: mapbox.Position(
          ui.lerpDouble(startLng, targetLng, progress)!,
          ui.lerpDouble(startLat, targetLat, progress)!,
        ),
      );
      await annotationManager.update(annotation);
      if (frame < frameCount) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  static Future<mapbox.PointAnnotationOptions> _markerOptions(
    double lat,
    double lng, {
    String? label,
    required bool isOrigin,
    Color? color,
  }) async {
    final markerColor =
        color ?? TripMapMarkerStyle.colorFor(isOrigin: isOrigin);
    return mapbox.PointAnnotationOptions(
      geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
      image: await _createMarkerImage(markerColor, label: label),
      iconAnchor: mapbox.IconAnchor.BOTTOM,
      iconSize: label == null ? TripMapMarkerStyle.pinIconSize : 1.0,
      symbolSortKey: isOrigin ? 10 : 20,
    );
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
    final background = Paint()..color = AppTheme.surface;
    final shadow = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.12);
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
    canvas.drawCircle(
      const Offset(48, 47),
      8,
      Paint()..color = AppTheme.surface,
    );

    final lines = label.split('\n');
    _drawLabelText(
      canvas,
      lines.first,
      const Offset(82, 25),
      width: 250,
      fontSize: 23,
      fontWeight: FontWeight.w700,
      color: AppTheme.primaryColor,
    );
    if (lines.length > 1) {
      _drawLabelText(
        canvas,
        lines.skip(1).join(' '),
        const Offset(82, 55),
        width: 250,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppTheme.primaryColor.withValues(alpha: 0.6),
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
    const width = 64.0;
    const height = 76.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(width / 2, 26);
    final outerTail = Path()
      ..moveTo(center.dx - 10, 41)
      ..lineTo(center.dx, height - 2)
      ..lineTo(center.dx + 10, 41)
      ..close();
    final innerTail = Path()
      ..moveTo(center.dx - 6, 40)
      ..lineTo(center.dx, height - 9)
      ..lineTo(center.dx + 6, 40)
      ..close();
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 23))
      ..addPath(outerTail, Offset.zero);

    canvas.drawShadow(
      shadowPath,
      AppTheme.primaryColor.withValues(alpha: 0.26),
      5,
      true,
    );
    canvas.drawPath(outerTail, Paint()..color = AppTheme.surface);
    canvas.drawPath(innerTail, Paint()..color = color);
    canvas.drawCircle(center, 23, Paint()..color = AppTheme.surface);
    canvas.drawCircle(center, 18, Paint()..color = color);
    canvas.drawCircle(center, 9, Paint()..color = AppTheme.surface);
    canvas.drawCircle(center, 4, Paint()..color = color);
    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  static Future<mapbox.PolylineAnnotationManager> addPolyline(
    AppMapController controller,
    List<List<double>> points, {
    Color color = AppTheme.primaryColor,
    double width = 4.0,
  }) async {
    final validPoints = points.where(_isValidPolylinePoint).toList();
    if (validPoints.length < 2) {
      throw ArgumentError.value(
        points,
        'points',
        'at least two valid coordinates are required',
      );
    }

    final mapCtrl = controller.native;
    final annotationManager = await mapCtrl.annotations
        .createPolylineAnnotationManager();

    final coordinates = validPoints
        .map((point) => mapbox.Position(point[0], point[1]))
        .toList();

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

  static Future<void> replacePolyline(
    mapbox.PolylineAnnotationManager annotationManager,
    List<List<double>> points, {
    Color color = AppTheme.primaryColor,
    double width = 4.0,
  }) async {
    final validPoints = points.where(_isValidPolylinePoint).toList();
    if (validPoints.length < 2) {
      throw ArgumentError.value(
        points,
        'points',
        'at least two valid coordinates are required',
      );
    }
    final coordinates = validPoints
        .map((point) => mapbox.Position(point[0], point[1]))
        .toList();
    final annotations = await annotationManager.getAnnotations();
    if (annotations.isEmpty) {
      await annotationManager.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: coordinates),
          lineWidth: width,
          lineColor: color.toARGB32(),
          lineJoin: mapbox.LineJoin.ROUND,
        ),
      );
      return;
    }
    final annotation = annotations.first;
    annotation.geometry = mapbox.LineString(coordinates: coordinates);
    annotation.lineWidth = width;
    annotation.lineColor = color.toARGB32();
    annotation.lineJoin = mapbox.LineJoin.ROUND;
    await annotationManager.update(annotation);
    if (annotations.length > 1) {
      await annotationManager.deleteMulti(annotations.skip(1).toList());
    }
  }

  static bool _isValidPolylinePoint(List<double> point) {
    return point.length >= 2 &&
        point[0].isFinite &&
        point[1].isFinite &&
        point[1] >= -90 &&
        point[1] <= 90 &&
        point[0] >= -180 &&
        point[0] <= 180;
  }

  static Future<void> clearAnnotations(
    mapbox.BaseAnnotationManager? manager,
  ) async {
    if (manager == null) return;
    try {
      switch (manager) {
        case final mapbox.PointAnnotationManager pointManager:
          await pointManager.deleteAll();
        case final mapbox.PolylineAnnotationManager polylineManager:
          await polylineManager.deleteAll();
        case final mapbox.CircleAnnotationManager circleManager:
          await circleManager.deleteAll();
        case final mapbox.PolygonAnnotationManager polygonManager:
          await polygonManager.deleteAll();
        case _:
          debugPrint(
            'Unsupported annotation manager type: ${manager.runtimeType}',
          );
      }
    } catch (error) {
      debugPrint('Error clearing annotations: $error');
    }
  }
}
