import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:foundation/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/src/device/device_location_service.dart';
import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';
import 'package:maps/src/domain/failures/place_failure.dart';
import 'package:maps/src/map/map_annotation_service.dart';
import 'package:maps/src/map/map_camera_service.dart';
import 'package:maps/src/map/map_native_service.dart';
import 'package:maps/src/support/nearby_place_resolver.dart';
import 'package:maps/src/support/route_request_key.dart';

export 'package:maps/src/map/map_annotation_service.dart';
export 'package:maps/src/map/map_camera_service.dart';

class MapProvider._() {
  static const double nearbyRadiusKm = 5.0;
  static const _routeCacheTtl = Duration(seconds: 20);
  static const _routeRetryDelay = Duration(milliseconds: 250);

  static bool _initialized = false;
  static MapNativeService? _nativeService;
  static final AsyncTtlCache<RouteRequestKey, Route?> _routeCache =
      AsyncTtlCache(ttl: _routeCacheTtl, maxEntries: 24);

  static String styleUriFor() => mapbox.MapboxStyles.MAPBOX_STREETS;

  static Future<void> initialize({
    String? token,
    required MapNativeService nativeService,
  }) async {
    if (_initialized) return;
    _nativeService = nativeService;
    _routeCache.clear();
    if (token != null && token.isNotEmpty) {
      mapbox.MapboxOptions.setAccessToken(token);
    }
    _initialized = true;
  }

  static Future<List<Place>> searchPlaces(
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

      return await either.fold(
        (failure) {
          debugPrint(
            'MapProvider.searchPlaces failure: ${failure.runtimeType}',
          );
          return <Place>[];
        },
        (places) => places.where((p) {
          final distance = p.distanceKm;
          return distance == null || distance <= 30.0;
        }).toList(),
      );
    } catch (_) {
      debugPrint('MapProvider.searchPlaces error.');
      return [];
    }
  }

  static Future<Place?> getPlaceFromCoordinates(double lat, double lng) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    try {
      final either = await nativeService.reverseGeocode(lat: lat, lng: lng);
      return await either.fold((failure) {
        debugPrint(
          'MapProvider.getPlaceFromCoordinates failure: ${failure.runtimeType}',
        );
        return null;
      }, (place) => place);
    } catch (_) {
      debugPrint('MapProvider.getPlaceFromCoordinates error.');
      return null;
    }
  }

  static Future<Route?> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng, {
    RoutePreference preference = RoutePreference.fastest,
    RouteProfile profile = RouteProfile.driving,
    List<({double lat, double lng})> excludePoints = const [],
  }) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    final key = RouteRequestKey(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      preference: preference,
      profile: profile,
      excludePoints: excludePoints,
    );

    return _routeCache.getOrLoad(
      key,
      () => _requestRoute(
        nativeService,
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        preference: preference,
        profile: profile,
        excludePoints: excludePoints,
      ),
      shouldCache: (route) => route != null,
    );
  }

  static Future<Route?> _requestRoute(
    MapNativeService nativeService, {
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required RoutePreference preference,
    required RouteProfile profile,
    required List<({double lat, double lng})> excludePoints,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final either = await nativeService.getRoute(
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
          preference: preference,
          profile: profile,
          excludePoints: excludePoints,
        );
        Route? route;
        var retryable = false;
        either.fold((failure) {
          debugPrint('MapProvider.getRoute failure: ${failure.runtimeType}');
          retryable = failure is PlaceNetworkError;
        }, (value) => route = value);
        if (route != null || !retryable || attempt == 1) return route;
      } catch (_) {
        debugPrint('MapProvider.getRoute error.');
        return null;
      }
      await Future<void>.delayed(_routeRetryDelay);
    }
    return null;
  }

  static Future<List<double>?> getDrivingDistances({
    required double originLat,
    required double originLng,
    required List<({double lat, double lng})> destinations,
  }) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }
    if (destinations.isEmpty) return const [];

    try {
      final either = await nativeService.getDrivingDistances(
        originLat: originLat,
        originLng: originLng,
        destinations: destinations,
      );
      return await either.fold((failure) {
        debugPrint(
          'MapProvider.getDrivingDistances failure: ${failure.runtimeType}',
        );
        return null;
      }, (distances) => distances);
    } catch (_) {
      debugPrint('MapProvider.getDrivingDistances error.');
      return null;
    }
  }

  static Future<List<Place>> getNearbyPOIs({
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
      return await either.fold(
        (failure) {
          debugPrint(
            'MapProvider.getNearbyPOIs failure: ${failure.runtimeType}',
          );
          return <Place>[];
        },
        (pois) => NearbyPlaceResolver.withinRadius(
          places: pois,
          latitude: lat,
          longitude: lng,
          radiusKm: nearbyRadiusKm,
        ),
      );
    } catch (_) {
      debugPrint('MapProvider.getNearbyPOIs error.');
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
    return Builder(
      builder: (context) {
        AppMapController? mapController;
        final styleUri = styleUriFor();

        return mapbox.MapWidget(
          key: ValueKey<String>(styleUri),
          styleUri: styleUri,
          viewport: mapbox.CameraViewportState(
            center: mapbox.Point(
              coordinates: mapbox.Position(longitude, latitude),
            ),
            zoom: zoom,
          ),
          onCameraChangeListener: (cameraChangedEventData) {
            final currentController = mapController;
            if (currentController != null) {
              onCameraChanged?.call(currentController);
            }
          },
          onMapIdleListener: (mapIdleEventData) {
            final currentController = mapController;
            if (currentController != null) {
              onMapIdle?.call(currentController);
            }
          },
          onMapCreated: (controller) {
            unawaited(
              controller.logo.updateSettings(
                mapbox.LogoSettings(enabled: false),
              ),
            );
            unawaited(
              controller.attribution.updateSettings(
                mapbox.AttributionSettings(enabled: false),
              ),
            );
            unawaited(
              controller.scaleBar.updateSettings(
                mapbox.ScaleBarSettings(enabled: false),
              ),
            );

            if (!interactive) {
              unawaited(
                controller.gestures.updateSettings(
                  mapbox.GesturesSettings(
                    scrollEnabled: false,
                    rotateEnabled: false,
                    pitchEnabled: false,
                    doubleTapToZoomInEnabled: false,
                    quickZoomEnabled: false,
                  ),
                ),
              );
            }

            final currentController = AppMapController(controller);
            mapController = currentController;
            if (showUserLocation) {
              unawaited(
                controller.location.updateSettings(
                  mapbox.LocationComponentSettings(
                    enabled: true,
                    pulsingEnabled: false,
                    showAccuracyRing: false,
                  ),
                ),
              );
            }
            onMapCreated?.call(currentController);
          },
        );
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

  static Future<mapbox.PointAnnotationManager> addMarker(
    AppMapController controller,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    VoidCallback? onTap,
  }) => MapAnnotationService.addMarker(
    controller,
    lat,
    lng,
    label: label,
    isOrigin: isOrigin,
    color: color,
    onTap: onTap,
  );

  static Future<void> replaceMarker(
    mapbox.PointAnnotationManager annotationManager,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    bool animate = false,
  }) => MapAnnotationService.replaceMarker(
    annotationManager,
    lat,
    lng,
    label: label,
    isOrigin: isOrigin,
    color: color,
    animate: animate,
  );

  static Future<mapbox.PolylineAnnotationManager> addPolyline(
    AppMapController controller,
    List<List<double>> points, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => MapAnnotationService.addPolyline(
    controller,
    points,
    color: color,
    width: width,
  );

  static Future<void> replacePolyline(
    mapbox.PolylineAnnotationManager annotationManager,
    List<List<double>> points, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => MapAnnotationService.replacePolyline(
    annotationManager,
    points,
    color: color,
    width: width,
  );

  static Future<void> clearAnnotations(mapbox.BaseAnnotationManager? manager) =>
      MapAnnotationService.clearAnnotations(manager);
}
