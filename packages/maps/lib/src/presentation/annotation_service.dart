import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart'
    show AppPalette, AppStatusColors;
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'package:maps/src/presentation/camera_service.dart';

typedef MapPointAnnotationManager = mapbox.PointAnnotationManager;
typedef MapPolylineAnnotationManager = mapbox.PolylineAnnotationManager;
typedef MapBaseAnnotationManager = mapbox.BaseAnnotationManager;

class TripMapMarkerStyle._() {
  static const double pinIconSize = 1.22;
  static const Color ownLocation = AppPalette.obsidian;
  static const Color tripLocation = AppStatusColors.success;
  static const Color markerSurface = AppPalette.white;
  static const Color labelForeground = AppPalette.obsidian;

  static Color colorFor({required bool isOrigin}) {
    return isOrigin ? ownLocation : tripLocation;
  }
}

abstract final class MapMarkerMotion {
  static double bearingBetween({
    required double startLatitude,
    required double startLongitude,
    required double targetLatitude,
    required double targetLongitude,
  }) {
    final startLatitudeRad = _radians(startLatitude);
    final targetLatitudeRad = _radians(targetLatitude);
    final longitudeDelta = _radians(targetLongitude - startLongitude);
    final x = math.sin(longitudeDelta) * math.cos(targetLatitudeRad);
    final y =
        math.cos(startLatitudeRad) * math.sin(targetLatitudeRad) -
        math.sin(startLatitudeRad) *
            math.cos(targetLatitudeRad) *
            math.cos(longitudeDelta);
    if (x == 0 && y == 0) return 0;
    return _normalize(math.atan2(x, y) * 180 / math.pi);
  }

  static double interpolateBearing(
    double start,
    double target,
    double progress,
  ) {
    final shortestDelta = _normalize(target - start + 180) - 180;
    return _normalize(start + shortestDelta * progress);
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  static double _normalize(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}

class MapAnnotationService._() {
  static const _markerImageCacheCapacity = 32;
  static final LinkedHashMap<String, Uint8List> _markerImageCache =
      LinkedHashMap();
  static final Expando<mapbox.MapboxMap> _annotationManagerOwners = Expando(
    'MapAnnotationService.annotationManagerOwners',
  );
  static final Map<String, int> _animationGenerationByManagerKey = {};

  static Future<mapbox.PointAnnotationManager> addMarker(
    AppMapController controller,
    double latitude,
    double longitude, {
    String? label,
    bool isOrigin = false,
    Color? color,
    double? bearing,
    VoidCallback? onTap,
  }) => traceTimelineStage('maps.marker.add', () async {
    final mapController = controller.native;
    final annotationManager = await mapController.annotations
        .createPointAnnotationManager();
    _annotationManagerOwners[annotationManager] = mapController;

    try {
      final options = await _markerOptions(
        latitude,
        longitude,
        label: label,
        isOrigin: isOrigin,
        color: color,
        bearing: bearing ?? 0,
      );
      await traceTimelineStage(
        'maps.marker.platform_create',
        () => annotationManager.create(options),
      );
      if (onTap != null) {
        annotationManager.tapEvents(onTap: (_) => onTap());
      }
      return annotationManager;
    } catch (_) {
      await clearAnnotations(annotationManager);
      rethrow;
    }
  });

  static Future<void> replaceMarker(
    mapbox.PointAnnotationManager annotationManager,
    double latitude,
    double longitude, {
    String? label,
    bool isOrigin = false,
    Color? color,
    double? bearing,
    bool animate = false,
  }) => traceTimelineStage('maps.marker.replace', () async {
    final annotations = await traceTimelineStage(
      'maps.marker.read_annotations',
      annotationManager.getAnnotations,
    );
    if (annotations.isEmpty) {
      final options = await _markerOptions(
        latitude,
        longitude,
        label: label,
        isOrigin: isOrigin,
        color: color,
        bearing: bearing ?? 0,
      );
      await traceTimelineStage(
        'maps.marker.platform_create',
        () => annotationManager.create(options),
      );
      return;
    }

    final annotation = annotations.first;
    final startLatitude = annotation.geometry.coordinates.lat.toDouble();
    final startLongitude = annotation.geometry.coordinates.lng.toDouble();
    final startBearing = annotation.iconRotate ?? 0;
    final targetBearing =
        bearing ??
        ((startLatitude - latitude).abs() < 0.000001 &&
                (startLongitude - longitude).abs() < 0.000001
            ? annotation.iconRotate ?? 0
            : MapMarkerMotion.bearingBetween(
                startLatitude: startLatitude,
                startLongitude: startLongitude,
                targetLatitude: latitude,
                targetLongitude: longitude,
              ));
    final options = await _markerOptions(
      latitude,
      longitude,
      label: label,
      isOrigin: isOrigin,
      color: color,
      bearing: targetBearing,
    );
    annotation.image = options.image;
    annotation.iconAnchor = options.iconAnchor;
    annotation.iconSize = options.iconSize;
    annotation.iconRotate = options.iconRotate;
    annotation.symbolSortKey = options.symbolSortKey;
    final generation =
        (_animationGenerationByManagerKey[annotationManager.id] ?? 0) + 1;
    _animationGenerationByManagerKey[annotationManager.id] = generation;
    if (animate) {
      await traceTimelineStage(
        'maps.marker.animate_8_updates',
        () => _animateMarker(
          annotationManager,
          annotation,
          startBearing: startBearing,
          targetLatitude: latitude,
          targetLongitude: longitude,
          targetBearing: targetBearing,
          generation: generation,
        ),
      );
    } else {
      annotation.geometry = options.geometry;
      await traceTimelineStage(
        'maps.marker.platform_update',
        () => annotationManager.update(annotation),
      );
    }
    if (annotations.length > 1) {
      await traceTimelineStage(
        'maps.marker.platform_delete_extras',
        () => annotationManager.deleteMulti(annotations.skip(1).toList()),
      );
    }
  });

  static Future<void> _animateMarker(
    mapbox.PointAnnotationManager annotationManager,
    mapbox.PointAnnotation annotation, {
    required double startBearing,
    required double targetLatitude,
    required double targetLongitude,
    required double targetBearing,
    required int generation,
  }) async {
    final startLatitude = annotation.geometry.coordinates.lat.toDouble();
    final startLongitude = annotation.geometry.coordinates.lng.toDouble();
    const frameCount = 8;
    for (var frame = 1; frame <= frameCount; frame++) {
      if (_animationGenerationByManagerKey[annotationManager.id] !=
          generation) {
        return;
      }
      final progress = Curves.easeInOut.transform(frame / frameCount);
      annotation.geometry = mapbox.Point(
        coordinates: mapbox.Position(
          ui.lerpDouble(startLongitude, targetLongitude, progress)!,
          ui.lerpDouble(startLatitude, targetLatitude, progress)!,
        ),
      );
      annotation.iconRotate = MapMarkerMotion.interpolateBearing(
        startBearing,
        targetBearing,
        progress,
      );
      await annotationManager.update(annotation);
      if (frame < frameCount) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (_animationGenerationByManagerKey[annotationManager.id] !=
            generation) {
          return;
        }
      }
    }
    if (_animationGenerationByManagerKey[annotationManager.id] == generation) {
      _animationGenerationByManagerKey.remove(annotationManager.id);
    }
  }

  static Future<mapbox.PointAnnotationOptions> _markerOptions(
    double latitude,
    double longitude, {
    String? label,
    required bool isOrigin,
    Color? color,
    required double bearing,
  }) async {
    final markerColor =
        color ?? TripMapMarkerStyle.colorFor(isOrigin: isOrigin);
    return mapbox.PointAnnotationOptions(
      geometry: mapbox.Point(coordinates: mapbox.Position(longitude, latitude)),
      image: await _createMarkerImage(markerColor, label: label),
      iconAnchor: mapbox.IconAnchor.BOTTOM,
      iconRotate: bearing,
      iconSize: label == null ? TripMapMarkerStyle.pinIconSize : 1.0,
      symbolSortKey: isOrigin ? 10 : 20,
    );
  }

  static Future<Uint8List> _createMarkerImage(
    Color color, {
    String? label,
  }) async {
    final cacheLabel = label == null || label.trim().isEmpty ? '' : label;
    final cacheKey = '${color.toARGB32()}_$cacheLabel';
    final cachedImage = _markerImageCache.remove(cacheKey);
    if (cachedImage != null) {
      _markerImageCache[cacheKey] = cachedImage;
      return cachedImage;
    }

    final image = await traceTimelineStage(
      'maps.marker.rasterize_png',
      () => _renderMarkerImage(color, label: label),
    );
    if (_markerImageCache.length >= _markerImageCacheCapacity) {
      _markerImageCache.remove(_markerImageCache.keys.first);
    }
    _markerImageCache[cacheKey] = image;
    return image;
  }

  static Future<Uint8List> _renderMarkerImage(
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
    final background = Paint()..color = TripMapMarkerStyle.markerSurface;
    final shadow = Paint()
      ..color = TripMapMarkerStyle.labelForeground.withValues(alpha: 0.12);
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
      Paint()..color = TripMapMarkerStyle.markerSurface,
    );

    final lines = label.split('\n');
    _drawLabelText(
      canvas,
      lines.first,
      const Offset(82, 25),
      width: 250,
      fontSize: 23,
      fontWeight: FontWeight.w700,
      color: TripMapMarkerStyle.labelForeground,
    );
    if (lines.length > 1) {
      _drawLabelText(
        canvas,
        lines.skip(1).join(' '),
        const Offset(82, 55),
        width: 250,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: TripMapMarkerStyle.labelForeground.withValues(alpha: 0.6),
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
      TripMapMarkerStyle.labelForeground.withValues(alpha: 0.26),
      5,
      true,
    );
    canvas.drawPath(
      outerTail,
      Paint()..color = TripMapMarkerStyle.markerSurface,
    );
    canvas.drawPath(innerTail, Paint()..color = color);
    canvas.drawCircle(
      center,
      23,
      Paint()..color = TripMapMarkerStyle.markerSurface,
    );
    canvas.drawCircle(center, 18, Paint()..color = color);
    canvas.drawCircle(
      center,
      9,
      Paint()..color = TripMapMarkerStyle.markerSurface,
    );
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
    Color color = TripMapMarkerStyle.ownLocation,
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

    final mapController = controller.native;
    final annotationManager = await mapController.annotations
        .createPolylineAnnotationManager();
    _annotationManagerOwners[annotationManager] = mapController;

    final coordinates = validPoints
        .map((point) => mapbox.Position(point[0], point[1]))
        .toList();

    try {
      await annotationManager.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: coordinates),
          lineWidth: width,
          lineColor: color.toARGB32(),
          lineJoin: mapbox.LineJoin.ROUND,
        ),
      );
      return annotationManager;
    } catch (_) {
      await clearAnnotations(annotationManager);
      rethrow;
    }
  }

  static Future<mapbox.PolylineAnnotationManager> addPolylineBuffer(
    AppMapController controller,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) async {
    final positions = _positionsFromBuffer(coordinates);
    final mapController = controller.native;
    final annotationManager = await mapController.annotations
        .createPolylineAnnotationManager();
    _annotationManagerOwners[annotationManager] = mapController;

    try {
      await annotationManager.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: positions),
          lineWidth: width,
          lineColor: color.toARGB32(),
          lineJoin: mapbox.LineJoin.ROUND,
        ),
      );
      return annotationManager;
    } catch (_) {
      await clearAnnotations(annotationManager);
      rethrow;
    }
  }

  static Future<void> replacePolyline(
    mapbox.PolylineAnnotationManager annotationManager,
    List<List<double>> points, {
    Color color = TripMapMarkerStyle.ownLocation,
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

  static Future<void> replacePolylineBuffer(
    mapbox.PolylineAnnotationManager annotationManager,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) async {
    final positions = _positionsFromBuffer(coordinates);
    final annotations = await annotationManager.getAnnotations();
    if (annotations.isEmpty) {
      await annotationManager.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: positions),
          lineWidth: width,
          lineColor: color.toARGB32(),
          lineJoin: mapbox.LineJoin.ROUND,
        ),
      );
      return;
    }
    final annotation = annotations.first;
    annotation.geometry = mapbox.LineString(coordinates: positions);
    annotation.lineWidth = width;
    annotation.lineColor = color.toARGB32();
    annotation.lineJoin = mapbox.LineJoin.ROUND;
    await annotationManager.update(annotation);
    if (annotations.length > 1) {
      await annotationManager.deleteMulti(annotations.skip(1).toList());
    }
  }

  static List<mapbox.Position> _positionsFromBuffer(Float64List coordinates) {
    final positions = <mapbox.Position>[];
    for (var index = 0; index + 1 < coordinates.length; index += 2) {
      final longitude = coordinates[index];
      final latitude = coordinates[index + 1];
      if (_isValidPolylineCoordinate(longitude, latitude)) {
        positions.add(mapbox.Position(longitude, latitude));
      }
    }
    if (positions.length < 2) {
      throw ArgumentError.value(
        coordinates,
        'coordinates',
        'at least two valid coordinates are required',
      );
    }
    return positions;
  }

  static bool _isValidPolylinePoint(List<double> point) {
    return point.length >= 2 && _isValidPolylineCoordinate(point[0], point[1]);
  }

  static bool _isValidPolylineCoordinate(double longitude, double latitude) {
    return longitude.isFinite &&
        latitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static Future<void> clearAnnotations(
    mapbox.BaseAnnotationManager? manager,
  ) async {
    if (manager == null) return;
    _animationGenerationByManagerKey.remove(manager.id);
    try {
      final owner = _annotationManagerOwners[manager];
      if (owner != null) {
        try {
          await owner.annotations.removeAnnotationManager(manager);
          _annotationManagerOwners[manager] = null;
          return;
        } catch (error) {
          debugPrint('Error removing annotation manager: $error');
        }
      }

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
