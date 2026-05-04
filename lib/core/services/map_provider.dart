import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:BaoRide/core/config/env_config.dart';
import 'package:BaoRide/core/models/place_model.dart';
import 'package:BaoRide/core/models/route_model.dart';
import 'package:BaoRide/core/services/location_service.dart';
import 'package:BaoRide/src/rust/application/map_api.dart' as rust_api;

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

/// The map controller wrapper. Screens hold this to manipulate the map.
/// Internally wraps the native controller (MapboxMap or GoogleMapController).
class AppMapController {
  final dynamic _native;
  AppMapController(this._native);

  /// Access native controller only within this file's implementation.
  dynamic get native => _native;
}

class MapProvider {
  MapProvider._();

  static bool _initialized = false;

  /// Initialize the map SDK. Call once in main.dart.
  static Future<void> initialize() async {
    if (_initialized) return;
    final token = EnvConfig.mapboxPublicToken;
    mapbox.MapboxOptions.setAccessToken(token);
    _initialized = true;
  }

  /// Forward geocoding: search for places by text query.
  /// [proximity] biases results toward the user's location.
  static Future<List<PlaceModel>> searchPlaces(
    String query, {
    double? lat,
    double? lng,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final token = EnvConfig.mapboxPublicToken;
      final userLat = lat ?? LocationService.lastPosition?.latitude;
      final userLng = lng ?? LocationService.lastPosition?.longitude;

      final rustResults = await rust_api.searchPlaces(
        token: token,
        query: query,
        proximityLat: lat,
        proximityLng: lng,
        userLat: userLat,
        userLng: userLng,
      );

      final places = rustResults
          .map(
            (r) => PlaceModel(
              id: r.id,
              name: r.name,
              fullAddress: r.fullAddress,
              latitude: r.latitude,
              longitude: r.longitude,
              category: r.category,
              distanceKm: r.distanceKm,
            ),
          )
          .toList();

      return places.where((p) {
        if (p.distanceKm == null) return true;
        return p.distanceKm! <= 30.0;
      }).toList();
    } catch (e) {
      debugPrint('MapProvider.searchPlaces error: $e');
      return [];
    }
  }

  /// Reverse geocoding: get place info from coordinates.
  static Future<PlaceModel?> getPlaceFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final token = EnvConfig.mapboxPublicToken;
      final rustResult = await rust_api.reverseGeocode(
        token: token,
        lat: lat,
        lng: lng,
      );

      if (rustResult == null) return null;

      return PlaceModel(
        id: rustResult.id,
        name: rustResult.name,
        fullAddress: rustResult.fullAddress,
        latitude: rustResult.latitude,
        longitude: rustResult.longitude,
        category: rustResult.category,
      );
    } catch (e) {
      debugPrint('MapProvider.getPlaceFromCoordinates error: $e');
      return null;
    }
  }

  /// Get a driving route between two points.
  /// Returns a RouteModel with decoded polyline coordinates.
  static Future<RouteModel?> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final token = EnvConfig.mapboxPublicToken;
      final rustResult = await rust_api.getRoute(
        token: token,
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (rustResult == null) return null;

      final points = rustResult.polylinePoints
          .map<List<double>>((p) => [p.lng, p.lat])
          .toList();

      return RouteModel(
        polylinePoints: points,
        distanceKm: rustResult.distanceKm,
        estimatedTime: Duration(seconds: rustResult.durationSeconds.round()),
        summary: rustResult.summary,
      );
    } catch (e) {
      debugPrint('MapProvider.getRoute error: $e');
      return null;
    }
  }

  /// Dynamically extract all Points of Interest from the map within a radius.
  static Future<List<PlaceModel>> getNearbyPOIs({
    required double lat,
    required double lng,
  }) async {
    try {
      final token = EnvConfig.mapboxPublicToken;
      final rustResults = await rust_api.getNearbyPois(
        token: token,
        lat: lat,
        lng: lng,
      );

      return rustResults.map((r) => PlaceModel(
        id: r.id,
        name: r.name,
        fullAddress: r.fullAddress,
        latitude: r.latitude,
        longitude: r.longitude,
        category: r.category,
        distanceKm: r.distanceKm,
      )).toList();
    } catch (e) {
      debugPrint('MapProvider.getNearbyPOIs error: $e');
      return [];
    }
  }

  /// Build a map widget. This is the ONLY place the native map widget is used.
  /// All screens call this method instead of using MapboxMap/GoogleMap directly.
  static Widget buildMapView({
    required double latitude,
    required double longitude,
    double zoom = 14.0,
    void Function(AppMapController controller)? onMapCreated,
    void Function(double lat, double lng)? onTap,
    void Function(double lat, double lng)? onCameraIdle,
    bool interactive = true,
    EdgeInsets? padding,
  }) {
    return mapbox.MapWidget(
      styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(longitude, latitude)),
        zoom: zoom,
      ),
      onMapCreated: (controller) {
        if (!interactive) {
          controller.gestures.updateSettings(
            mapbox.GesturesSettings(
              scrollEnabled: false,
              rotateEnabled: false,
              pitchEnabled: false,
              doubleTapToZoomInEnabled: false,
              quickZoomEnabled: false,
            ),
          );
        }

        onMapCreated?.call(AppMapController(controller));
      },
    );
  }

  /// Move camera to a position.
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

  /// Get the current center coordinates of the map.
  static Future<LatLng> getCameraCenter(AppMapController controller) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final camera = await mapCtrl.getCameraState();
    final center = camera.center;
    return LatLng(
      center.coordinates.lat.toDouble(),
      center.coordinates.lng.toDouble(),
    );
  }

  /// Add a point annotation (marker) to the map.
  static Future<void> addMarker(
    AppMapController controller,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
  }) async {
    final mapCtrl = controller.native as mapbox.MapboxMap;
    final annotationManager = await mapCtrl.annotations
        .createCircleAnnotationManager();

    await annotationManager.create(
      mapbox.CircleAnnotationOptions(
        geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
        circleRadius: isOrigin ? 8.0 : 10.0,
        circleColor: isOrigin ? 0xFF222222 : 0xFF607B8B,
        circleStrokeWidth: 3.0,
        circleStrokeColor: 0xFFFFFFFF,
      ),
    );
  }

  /// Add a polyline (route line) to the map.
  /// [points] is [[lng, lat], ...]
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

  /// Add a subset of polyline points (for animated progressive reveal).
  /// Returns the annotation manager so it can be cleared on next frame.
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

  /// Clears an annotation manager.
  static Future<void> clearAnnotations(dynamic manager) async {
    if (manager != null) {
      try {
        await manager.deleteAll();
      } catch (e) {
        debugPrint('Error clearing annotations: $e');
      }
    }
  }

  /// Fit the map camera to show all given coordinates with padding.
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
