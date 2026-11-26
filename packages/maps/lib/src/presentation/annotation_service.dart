import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:foundation/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/src/presentation/camera_service.dart';
import 'package:maps/src/presentation/marker_bitmap_renderer.dart';
import 'package:maps/src/presentation/marker_style_and_motion.dart';
import 'package:maps/src/presentation/polyline_annotation_controller.dart';
import 'package:material_ui/material_ui.dart';

export 'package:maps/src/presentation/marker_style_and_motion.dart';

typedef MapPointAnnotationManager = mapbox.PointAnnotationManager;
typedef MapPolylineAnnotationManager = mapbox.PolylineAnnotationManager;
typedef MapBaseAnnotationManager = mapbox.BaseAnnotationManager;

class MapAnnotationService._() {
  static final Expando<mapbox.MapboxMap> _annotationManagerOwners = Expando(
    'MapAnnotationService.annotationManagerOwners',
  );
  static final Expando<Future<void>> _annotationManagerCleanup = Expando(
    'MapAnnotationService.annotationManagerCleanup',
  );
  static final Expando<int> _animationGenerationByManager = Expando(
    'MapAnnotationService.animationGenerationByManager',
  );
  static final Expando<String> _markerImageKeyByManager = Expando(
    'MapAnnotationService.markerImageKeyByManager',
  );

  static void _registerOwner(
    mapbox.BaseAnnotationManager manager,
    mapbox.MapboxMap owner,
  ) {
    _annotationManagerOwners[manager] = owner;
  }

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
    _registerOwner(annotationManager, mapController);

    try {
      final imageKey = MarkerBitmapRenderer.cacheKey(
        color ?? TripMapMarkerStyle.colorFor(isOrigin: isOrigin),
        label: label,
      );
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
      _markerImageKeyByManager[annotationManager] = imageKey;
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
    final generation =
        (_animationGenerationByManager[annotationManager] ?? 0) + 1;
    _animationGenerationByManager[annotationManager] = generation;
    final imageKey = MarkerBitmapRenderer.cacheKey(
      color ?? TripMapMarkerStyle.colorFor(isOrigin: isOrigin),
      label: label,
    );

    final annotations = await traceTimelineStage(
      'maps.marker.read_annotations',
      annotationManager.getAnnotations,
    );
    if (_animationGenerationByManager[annotationManager] != generation) {
      return;
    }
    if (annotations.isEmpty) {
      final options = await _markerOptions(
        latitude,
        longitude,
        label: label,
        isOrigin: isOrigin,
        color: color,
        bearing: bearing ?? 0,
      );
      if (_animationGenerationByManager[annotationManager] != generation) {
        return;
      }
      await traceTimelineStage(
        'maps.marker.platform_create',
        () => annotationManager.create(options),
      );
      _markerImageKeyByManager[annotationManager] = imageKey;
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
    final imageChanged =
        _markerImageKeyByManager[annotationManager] != imageKey;
    if (imageChanged) {
      final markerColor =
          color ?? TripMapMarkerStyle.colorFor(isOrigin: isOrigin);
      annotation.image = await MarkerBitmapRenderer.getOrRender(
        markerColor,
        label: label,
      );
      if (_animationGenerationByManager[annotationManager] != generation) {
        return;
      }
      _markerImageKeyByManager[annotationManager] = imageKey;
    }
    annotation.iconAnchor = mapbox.IconAnchor.BOTTOM;
    annotation.iconSize = label == null ? TripMapMarkerStyle.pinIconSize : 1.0;
    annotation.iconRotate = targetBearing;
    annotation.symbolSortKey = isOrigin ? 10 : 20;
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
      annotation.geometry = mapbox.Point(
        coordinates: mapbox.Position(longitude, latitude),
      );
      await traceTimelineStage(
        'maps.marker.platform_update',
        () => annotationManager.update(annotation),
      );
    }
    if (annotations.length > 1 &&
        _animationGenerationByManager[annotationManager] == generation) {
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
      if (_animationGenerationByManager[annotationManager] != generation) {
        return;
      }
      final progress = Curves.easeInOut.transform(frame / frameCount);
      final nextLongitude =
          ui.lerpDouble(startLongitude, targetLongitude, progress) ??
          targetLongitude;
      final nextLatitude =
          ui.lerpDouble(startLatitude, targetLatitude, progress) ??
          targetLatitude;
      annotation.geometry = mapbox.Point(
        coordinates: mapbox.Position(nextLongitude, nextLatitude),
      );
      annotation.iconRotate = MapMarkerMotion.interpolateBearing(
        startBearing,
        targetBearing,
        progress,
      );
      await annotationManager.update(annotation);
      if (frame < frameCount) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (_animationGenerationByManager[annotationManager] != generation) {
          return;
        }
      }
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
      image: await MarkerBitmapRenderer.getOrRender(markerColor, label: label),
      iconAnchor: mapbox.IconAnchor.BOTTOM,
      iconRotate: bearing,
      iconSize: label == null ? TripMapMarkerStyle.pinIconSize : 1.0,
      symbolSortKey: isOrigin ? 10 : 20,
    );
  }

  static Future<mapbox.PolylineAnnotationManager> addPolyline(
    AppMapController controller,
    List<List<double>> points, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => PolylineAnnotationController.addPolyline(
    controller,
    points,
    registerOwner: _registerOwner,
    clearAnnotations: clearAnnotations,
    color: color,
    width: width,
  );

  static Future<mapbox.PolylineAnnotationManager> addPolylineBuffer(
    AppMapController controller,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => PolylineAnnotationController.addPolylineBuffer(
    controller,
    coordinates,
    registerOwner: _registerOwner,
    clearAnnotations: clearAnnotations,
    color: color,
    width: width,
  );

  static Future<void> replacePolyline(
    mapbox.PolylineAnnotationManager annotationManager,
    List<List<double>> points, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => PolylineAnnotationController.replacePolyline(
    annotationManager,
    points,
    color: color,
    width: width,
  );

  static Future<void> replacePolylineBuffer(
    mapbox.PolylineAnnotationManager annotationManager,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => PolylineAnnotationController.replacePolylineBuffer(
    annotationManager,
    coordinates,
    color: color,
    width: width,
  );

  static Future<void> clearAnnotations(
    mapbox.BaseAnnotationManager? manager,
  ) async {
    if (manager == null) return;
    return _annotationManagerCleanup[manager] ??= _clearAnnotations(manager);
  }

  static Future<void> _clearAnnotations(
    mapbox.BaseAnnotationManager manager,
  ) async {
    if (manager is mapbox.PointAnnotationManager) {
      _animationGenerationByManager[manager] =
          (_animationGenerationByManager[manager] ?? 0) + 1;
      _markerImageKeyByManager[manager] = null;
    }
    final owner = _annotationManagerOwners[manager];
    _annotationManagerOwners[manager] = null;
    try {
      if (owner != null) {
        // A disposed map may reject removal. Never fall back to deleteAll:
        // Android can crash if the native manager no longer exists.
        await owner.annotations.removeAnnotationManager(manager);
        return;
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
