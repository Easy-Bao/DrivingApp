import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:location_service/src/repositories/map_native_service.dart';
import 'package:location_service/src/services/device_location_service.dart';
import 'package:location_service/src/services/map_annotation_service.dart';
import 'package:location_service/src/services/map_camera_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

export 'package:location_service/src/services/map_annotation_service.dart';
export 'package:location_service/src/services/map_camera_service.dart';

class MapProvider {
  MapProvider._();

  static const double nearbyRadiusKm = 5.0;

  static bool _initialized = false;
  static MapNativeService? _nativeService;

  static Future<void> initialize({
    String? token,
    required MapNativeService nativeService,
  }) async {
    if (_initialized) return;
    _nativeService = nativeService;
    if (token != null && token.isNotEmpty) {
      mapbox.MapboxOptions.setAccessToken(token);
    }
    _initialized = true;
  }

  static Future<List<PlaceModel>> searchPlaces(
    String query, {
    double? lat,
    double? lng,
  }) async {
    if (query.trim().isEmpty) return [];

    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    try {
      final userLat = lat ?? LocationService.lastPosition?.latitude;
      final userLng = lng ?? LocationService.lastPosition?.longitude;

      final either = await nativeService.searchPlaces(
        query: query,
        proximityLat: lat,
        proximityLng: lng,
        userLat: userLat,
        userLng: userLng,
      );

      return either.fold(
        (failure) {
          debugPrint('MapProvider.searchPlaces failure: $failure');
          return <PlaceModel>[];
        },
        (places) => places.where((p) {
          if (p.distanceKm == null) return true;
          return p.distanceKm! <= 30.0;
        }).toList(),
      );
    } catch (error) {
      debugPrint('MapProvider.searchPlaces error: $error');
      return [];
    }
  }

  static Future<PlaceModel?> getPlaceFromCoordinates(
    double lat,
    double lng,
  ) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    try {
      final either = await nativeService.reverseGeocode(lat: lat, lng: lng);
      return either.fold((failure) {
        debugPrint('MapProvider.getPlaceFromCoordinates failure: $failure');
        return null;
      }, (place) => place);
    } catch (error) {
      debugPrint('MapProvider.getPlaceFromCoordinates error: $error');
      return null;
    }
  }

  static Future<RouteModel?> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    try {
      final either = await nativeService.getRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );
      return either.fold((failure) {
        debugPrint('MapProvider.getRoute failure: $failure');
        return null;
      }, (route) => route);
    } catch (error) {
      debugPrint('MapProvider.getRoute error: $error');
      return null;
    }
  }

  static Future<List<PlaceModel>> getNearbyPOIs({
    required double lat,
    required double lng,
    int page = 1,
  }) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    try {
      final either = await nativeService.getNearbyPois(
        lat: lat,
        lng: lng,
        page: page,
      );
      return either.fold(
        (failure) {
          debugPrint('MapProvider.getNearbyPOIs failure: $failure');
          return <PlaceModel>[];
        },
        (pois) => pois.where((place) {
          final distance = place.distanceKm;
          return distance != null && distance <= nearbyRadiusKm;
        }).toList(),
      );
    } catch (error) {
      debugPrint('MapProvider.getNearbyPOIs error: $error');
      return [];
    }
  }

  static Widget buildMapView({
    required double latitude,
    required double longitude,
    double zoom = 14.0,
    void Function(AppMapController controller)? onMapCreated,
    void Function(AppMapController controller)? onCameraChanged,
    void Function(AppMapController controller)? onMapIdle,
    bool interactive = true,
    bool showUserLocation = false,
    EdgeInsets? padding,
  }) {
    AppMapController? mapController;

    return mapbox.MapWidget(
      styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
      viewport: mapbox.CameraViewportState(
        center: mapbox.Point(coordinates: mapbox.Position(longitude, latitude)),
        zoom: zoom,
      ),
      onCameraChangeListener: (cameraChangedEventData) {
        if (mapController != null) {
          onCameraChanged?.call(mapController!);
        }
      },
      onMapIdleListener: (mapIdleEventData) {
        if (mapController != null) {
          onMapIdle?.call(mapController!);
        }
      },
      onMapCreated: (controller) {
        controller.logo.updateSettings(mapbox.LogoSettings(enabled: false));
        controller.attribution.updateSettings(
          mapbox.AttributionSettings(enabled: false),
        );

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

        mapController = AppMapController(controller);
        if (showUserLocation) {
          controller.location.updateSettings(
            mapbox.LocationComponentSettings(
              enabled: true,
              pulsingEnabled: false,
              showAccuracyRing: false,
            ),
          );
        }
        onMapCreated?.call(mapController!);
      },
    );
  }

  static Future<void> moveCamera(
    AppMapController controller,
    double lat,
    double lng, {
    double? zoom,
    bool animate = true,
  }) => MapCameraService.moveCamera(
    controller,
    lat,
    lng,
    zoom: zoom,
    animate: animate,
  );

  static Future<LatLng> getCameraCenter(AppMapController controller) =>
      MapCameraService.getCameraCenter(controller);

  static Future<Offset> getScreenCoordinate(
    AppMapController controller,
    double lat,
    double lng,
  ) => MapCameraService.getScreenCoordinate(controller, lat, lng);

  static Future<void> fitBounds(
    AppMapController controller,
    List<LatLng> points, {
    double padding = 80.0,
    double? maxZoom,
  }) => MapCameraService.fitBounds(
    controller,
    points,
    padding: padding,
    maxZoom: maxZoom,
  );

  static Future<void> zoomIn(AppMapController controller) =>
      MapCameraService.zoomIn(controller);

  static Future<void> zoomOut(AppMapController controller) =>
      MapCameraService.zoomOut(controller);

  static Future<dynamic> addMarker(
    AppMapController controller,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
  }) => MapAnnotationService.addMarker(
    controller,
    lat,
    lng,
    label: label,
    isOrigin: isOrigin,
    color: color,
  );

  static Future<void> addPolyline(
    AppMapController controller,
    List<List<double>> points, {
    Color color = const Color(0xFF222222),
    double width = 4.0,
  }) => MapAnnotationService.addPolyline(
    controller,
    points,
    color: color,
    width: width,
  );

  static Future<dynamic> addAnimatedPolylineSegment(
    AppMapController controller,
    List<List<double>> points, {
    Color color = const Color(0xFF222222),
    double width = 5.0,
  }) => MapAnnotationService.addAnimatedPolylineSegment(
    controller,
    points,
    color: color,
    width: width,
  );

  static Future<void> clearAnnotations(dynamic manager) =>
      MapAnnotationService.clearAnnotations(manager);
}
