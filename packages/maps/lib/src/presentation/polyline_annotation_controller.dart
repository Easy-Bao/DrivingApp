import 'dart:typed_data';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/src/presentation/camera_service.dart';
import 'package:maps/src/presentation/marker_style_and_motion.dart';
import 'package:material_ui/material_ui.dart';

class PolylineAnnotationController._() {
  static Future<mapbox.PolylineAnnotationManager> addPolyline(
    AppMapController controller,
    List<List<double>> points, {
    required void Function(
      mapbox.BaseAnnotationManager manager,
      mapbox.MapboxMap owner,
    )
    registerOwner,
    required Future<void> Function(mapbox.BaseAnnotationManager? manager)
    clearAnnotations,
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) {
    return _addPolylinePositions(
      controller,
      _positionsFromPoints(points),
      registerOwner: registerOwner,
      clearAnnotations: clearAnnotations,
      color: color,
      width: width,
    );
  }

  static Future<mapbox.PolylineAnnotationManager> addPolylineBuffer(
    AppMapController controller,
    Float64List coordinates, {
    required void Function(
      mapbox.BaseAnnotationManager manager,
      mapbox.MapboxMap owner,
    )
    registerOwner,
    required Future<void> Function(mapbox.BaseAnnotationManager? manager)
    clearAnnotations,
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) {
    return _addPolylinePositions(
      controller,
      _positionsFromBuffer(coordinates),
      registerOwner: registerOwner,
      clearAnnotations: clearAnnotations,
      color: color,
      width: width,
    );
  }

  static Future<void> replacePolyline(
    mapbox.PolylineAnnotationManager annotationManager,
    List<List<double>> points, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) {
    return _replacePolylinePositions(
      annotationManager,
      _positionsFromPoints(points),
      color: color,
      width: width,
    );
  }

  static Future<void> replacePolylineBuffer(
    mapbox.PolylineAnnotationManager annotationManager,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) {
    return _replacePolylinePositions(
      annotationManager,
      _positionsFromBuffer(coordinates),
      color: color,
      width: width,
    );
  }

  static Future<mapbox.PolylineAnnotationManager> _addPolylinePositions(
    AppMapController controller,
    List<mapbox.Position> positions, {
    required void Function(
      mapbox.BaseAnnotationManager manager,
      mapbox.MapboxMap owner,
    )
    registerOwner,
    required Future<void> Function(mapbox.BaseAnnotationManager? manager)
    clearAnnotations,
    required Color color,
    required double width,
  }) async {
    final mapController = controller.native;
    final annotationManager = await mapController.annotations
        .createPolylineAnnotationManager();
    registerOwner(annotationManager, mapController);

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

  static Future<void> _replacePolylinePositions(
    mapbox.PolylineAnnotationManager annotationManager,
    List<mapbox.Position> positions, {
    required Color color,
    required double width,
  }) async {
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

  static List<mapbox.Position> _positionsFromPoints(List<List<double>> points) {
    final positions = <mapbox.Position>[];
    for (final point in points) {
      if (_isValidPolylinePoint(point)) {
        positions.add(mapbox.Position(point[0], point[1]));
      }
    }
    if (positions.length < 2) {
      throw ArgumentError.value(
        points,
        'points',
        'at least two valid coordinates are required',
      );
    }
    return positions;
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
}
