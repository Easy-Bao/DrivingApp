import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Route;
import 'package:foundation/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/src/data/datasources/device_location_service.dart';
import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';
import 'package:maps/src/domain/failures/place_failure.dart';
import 'package:maps/src/presentation/annotation_service.dart';
import 'package:maps/src/presentation/camera_service.dart';
import 'package:maps/src/presentation/native_service.dart';
import 'package:maps/src/data/services/nearby_place_resolver.dart';
import 'package:maps/src/data/services/route_request_key.dart';

export 'package:maps/src/presentation/annotation_service.dart';
export 'package:maps/src/presentation/camera_service.dart';

class MapProvider._() {
  static const double nearbyRadiusKm = 5.0;
  static const _lookupCacheTtl = Duration(seconds: 15);
  static const _routeCacheTtl = Duration(seconds: 20);
  static const _routeRetryDelay = Duration(milliseconds: 250);

  static bool _initialized = false;
  static MapNativeService? _nativeService;
  static final AsyncTtlCache<String, List<Place>> _searchCache = AsyncTtlCache(
    ttl: _lookupCacheTtl,
    maxEntries: 24,
  );
  static final AsyncTtlCache<String, List<Place>> _nearbyCache = AsyncTtlCache(
    ttl: _lookupCacheTtl,
    maxEntries: 24,
  );
  static final AsyncTtlCache<String, List<double>?> _drivingDistanceCache =
      AsyncTtlCache(ttl: _lookupCacheTtl, maxEntries: 24);
  static final AsyncTtlCache<RouteRequestKey, Route?> _routeCache =
      AsyncTtlCache(ttl: _routeCacheTtl, maxEntries: 24);

  static String styleUriFor() => mapbox.MapboxStyles.MAPBOX_STREETS;

  static Future<void> initialize({
    String? token,
    required MapNativeService nativeService,
  }) async {
    if (_initialized) return;
    _nativeService = nativeService;
    clearLookupCaches();
    if (token != null && token.isNotEmpty) {
      mapbox.MapboxOptions.setAccessToken(token);
    }
    _initialized = true;
  }

  /// Drops values that may have been resolved before a background network
  /// transition. The next visible feature request must reach the server
  /// instead of reusing a stale empty or route response.
  static void clearLookupCaches() {
    _searchCache.clear();
    _nearbyCache.clear();
    _drivingDistanceCache.clear();
    _routeCache.clear();
  }

  static Future<List<Place>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    if (query.trim().isEmpty) return [];

    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    final userLatitude = latitude ?? LocationService.lastPosition?.latitude;
    final userLongitude = longitude ?? LocationService.lastPosition?.longitude;
    final key = _searchRequestKey(query, userLatitude, userLongitude);

    try {
      return await _searchCache.getOrLoad(key, () async {
        final result = await nativeService.searchPlaces(
          query: query,
          proximityLatitude: latitude,
          proximityLongitude: longitude,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );

        return result.fold(
          (failure) {
            debugPrint(
              'MapProvider.searchPlaces failure: ${failure.runtimeType}',
            );
            throw const _MapProviderLookupFailure();
          },
          (places) => places
              .where((p) {
                final distance = p.distanceKm;
                return distance == null || distance <= 30.0;
              })
              .toList(growable: false),
        );
      });
    } on _MapProviderLookupFailure {
      return [];
    } catch (_) {
      debugPrint('MapProvider.searchPlaces error.');
      return [];
    }
  }

  static Future<Place?> getPlaceFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    try {
      final result = await nativeService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
      return await result.fold((failure) {
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
    double originLatitude,
    double originLongitude,
    double destinationLatitude,
    double destinationLongitude, {
    RoutePreference preference = RoutePreference.fastest,
    RouteProfile profile = RouteProfile.driving,
    List<({double latitude, double longitude})> excludePoints = const [],
  }) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    final key = RouteRequestKey(
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      preference: preference,
      profile: profile,
      excludePoints: excludePoints,
    );

    return traceTimelineStage(
      'maps.route.cache_lookup',
      () => _routeCache.getOrLoad(
        key,
        () => _requestRoute(
          nativeService,
          originLatitude: originLatitude,
          originLongitude: originLongitude,
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
          preference: preference,
          profile: profile,
          excludePoints: excludePoints,
        ),
        shouldCache: (route) => route != null,
      ),
    );
  }

  static Future<Route?> _requestRoute(
    MapNativeService nativeService, {
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required RoutePreference preference,
    required RouteProfile profile,
    required List<({double latitude, double longitude})> excludePoints,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await traceTimelineStage(
          'maps.route.provider_request',
          () => nativeService.getRoute(
            originLatitude: originLatitude,
            originLongitude: originLongitude,
            destinationLatitude: destinationLatitude,
            destinationLongitude: destinationLongitude,
            preference: preference,
            profile: profile,
            excludePoints: excludePoints,
          ),
        );
        Route? route;
        var retryable = false;
        result.fold((failure) {
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
    required double originLatitude,
    required double originLongitude,
    required List<({double latitude, double longitude})> destinations,
  }) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }
    if (destinations.isEmpty) return const [];

    final key = _drivingDistanceRequestKey(
      originLatitude,
      originLongitude,
      destinations,
    );
    try {
      return await _drivingDistanceCache.getOrLoad(key, () async {
        final result = await nativeService.getDrivingDistances(
          originLatitude: originLatitude,
          originLongitude: originLongitude,
          destinations: destinations,
        );
        return result.fold((failure) {
          debugPrint(
            'MapProvider.getDrivingDistances failure: ${failure.runtimeType}',
          );
          return null;
        }, (distances) => distances);
      }, shouldCache: (distances) => distances != null);
    } catch (_) {
      debugPrint('MapProvider.getDrivingDistances error.');
      return null;
    }
  }

  static Future<List<Place>> getNearbyPOIs({
    required double latitude,
    required double longitude,
    int page = 1,
  }) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }

    final key = _nearbyRequestKey(latitude, longitude, page);
    try {
      return await _nearbyCache.getOrLoad(key, () async {
        final result = await nativeService.getNearbyPois(
          latitude: latitude,
          longitude: longitude,
          page: page,
        );
        return result.fold(
          (failure) {
            debugPrint(
              'MapProvider.getNearbyPOIs failure: ${failure.runtimeType}',
            );
            throw const _MapProviderLookupFailure();
          },
          (pois) => NearbyPlaceResolver.withinRadius(
            places: pois,
            latitude: latitude,
            longitude: longitude,
            radiusKm: nearbyRadiusKm,
          ),
        );
      });
    } on _MapProviderLookupFailure {
      return [];
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
    VoidCallback? onMapLoaded,
    void Function(AppMapController controller)? onCameraChanged,
    void Function(AppMapController controller)? onMapIdle,
    bool interactive = true,
    bool showUserLocation = false,
    EdgeInsets? padding,
  }) {
    return _AppMapView(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
      styleUri: styleUriFor(),
      onMapCreated: onMapCreated,
      onMapLoaded: onMapLoaded,
      onCameraChanged: onCameraChanged,
      onMapIdle: onMapIdle,
      interactive: interactive,
      showUserLocation: showUserLocation,
      padding: padding,
    );
  }

  static Future<void> moveCamera(
    AppMapController controller,
    double lat,
    double lng, {
    double? zoom,
    EdgeInsets? viewportPadding,
    bool animate = true,
  }) => MapCameraService.moveCamera(
    controller,
    lat,
    lng,
    zoom: zoom,
    viewportPadding: viewportPadding,
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
    EdgeInsets? viewportPadding,
    double? maxZoom,
  }) => MapCameraService.fitBounds(
    controller,
    points,
    padding: padding,
    viewportPadding: viewportPadding,
    maxZoom: maxZoom,
  );

  static Future<mapbox.PointAnnotationManager> addMarker(
    AppMapController controller,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    double? bearing,
    VoidCallback? onTap,
  }) => MapAnnotationService.addMarker(
    controller,
    lat,
    lng,
    label: label,
    isOrigin: isOrigin,
    color: color,
    bearing: bearing,
    onTap: onTap,
  );

  static Future<void> replaceMarker(
    mapbox.PointAnnotationManager annotationManager,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    double? bearing,
    bool animate = false,
  }) => MapAnnotationService.replaceMarker(
    annotationManager,
    lat,
    lng,
    label: label,
    isOrigin: isOrigin,
    color: color,
    bearing: bearing,
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

  static Future<mapbox.PolylineAnnotationManager> addPolylineBuffer(
    AppMapController controller,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => MapAnnotationService.addPolylineBuffer(
    controller,
    coordinates,
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

  static Future<void> replacePolylineBuffer(
    mapbox.PolylineAnnotationManager annotationManager,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => MapAnnotationService.replacePolylineBuffer(
    annotationManager,
    coordinates,
    color: color,
    width: width,
  );

  static Future<void> clearAnnotations(mapbox.BaseAnnotationManager? manager) =>
      MapAnnotationService.clearAnnotations(manager);
}

class _AppMapView extends StatefulWidget {
  const _AppMapView({
    required this.latitude,
    required this.longitude,
    required this.styleUri,
    required this.onMapCreated,
    required this.onMapLoaded,
    required this.onCameraChanged,
    required this.onMapIdle,
    required this.interactive,
    required this.showUserLocation,
    this.zoom = 14.0,
    this.padding,
  });

  final double latitude;
  final double longitude;
  final double zoom;
  final String styleUri;
  final void Function(AppMapController controller)? onMapCreated;
  final VoidCallback? onMapLoaded;
  final void Function(AppMapController controller)? onCameraChanged;
  final void Function(AppMapController controller)? onMapIdle;
  final bool interactive;
  final bool showUserLocation;
  final EdgeInsets? padding;

  @override
  State<_AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<_AppMapView> {
  AppMapController? _mapController;
  bool _mapLoaded = false;
  bool _mapLoadFailed = false;
  (String, int)? _preparingMap;
  int _mapGeneration = 0;

  @override
  void didUpdateWidget(_AppMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.styleUri != oldWidget.styleUri) {
      _mapController = null;
      _mapLoaded = false;
      _mapLoadFailed = false;
    }
  }

  Future<void> _finishLoading((String, int) identity) async {
    if (!mounted ||
        _mapLoaded ||
        _preparingMap == identity ||
        identity != (widget.styleUri, _mapGeneration))
      return;
    _preparingMap = identity;
    try {
      final controller = _mapController;
      if (controller != null) {
        await Future.wait([
          controller.native.logo.updateSettings(
            mapbox.LogoSettings(enabled: false),
          ),
          controller.native.attribution.updateSettings(
            mapbox.AttributionSettings(enabled: false),
          ),
          controller.native.scaleBar.updateSettings(
            mapbox.ScaleBarSettings(enabled: false),
          ),
        ]);
      }
      if (!mounted || identity != (widget.styleUri, _mapGeneration)) return;
      setState(() {
        _mapLoaded = true;
        _mapLoadFailed = false;
      });
      widget.onMapLoaded?.call();
    } catch (_) {
      if (mounted && identity == (widget.styleUri, _mapGeneration)) {
        setState(() => _mapLoadFailed = true);
      }
    } finally {
      if (_preparingMap == identity) _preparingMap = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapIdentity = (widget.styleUri, _mapGeneration);
    final map = mapbox.MapWidget(
      key: ValueKey(mapIdentity),
      // ignore: experimental_member_use
      androidHostingMode: mapbox.AndroidPlatformViewHostingMode.TLHC_HC,
      textureView: true,
      styleUri: widget.styleUri,
      viewport: mapbox.CameraViewportState(
        center: mapbox.Point(
          coordinates: mapbox.Position(widget.longitude, widget.latitude),
        ),
        zoom: widget.zoom,
        padding: widget.padding,
      ),
      onMapLoadedListener: (_) => unawaited(_finishLoading(mapIdentity)),
      onMapLoadErrorListener: (_) {
        if (!mounted ||
            _mapLoaded ||
            _mapLoadFailed ||
            mapIdentity != (widget.styleUri, _mapGeneration))
          return;
        setState(() => _mapLoadFailed = true);
      },
      onCameraChangeListener: (cameraChangedEventData) {
        final currentController = _mapController;
        if (currentController != null) {
          widget.onCameraChanged?.call(currentController);
        }
      },
      onMapIdleListener: (mapIdleEventData) {
        final currentController = _mapController;
        if (currentController != null) {
          widget.onMapIdle?.call(currentController);
        }
      },
      onMapCreated: (controller) {
        if (!mounted || mapIdentity != (widget.styleUri, _mapGeneration))
          return;

        if (!widget.interactive) {
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
        _mapController = currentController;
        if (widget.showUserLocation) {
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
        widget.onMapCreated?.call(currentController);
      },
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        map,
        if (!_mapLoaded)
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_mapLoadFailed) ...[
                        const Text(
                          'The map couldn’t load. Please try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => setState(() {
                            _mapController = null;
                            _mapLoadFailed = false;
                            _mapGeneration++;
                          }),
                          child: const Text('Retry'),
                        ),
                      ] else ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        const Text('Loading map…'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _searchRequestKey(String query, double? latitude, double? longitude) =>
    '${query.trim().toLowerCase()}|${_coordinateCacheKey(latitude)}|${_coordinateCacheKey(longitude)}';

String _nearbyRequestKey(double latitude, double longitude, int page) =>
    '${_coordinateCacheKey(latitude)}|${_coordinateCacheKey(longitude)}|$page';

String _drivingDistanceRequestKey(
  double originLatitude,
  double originLongitude,
  List<({double latitude, double longitude})> destinations,
) {
  final destinationKey = destinations
      .map(
        (destination) =>
            '${_coordinateCacheKey(destination.latitude)},${_coordinateCacheKey(destination.longitude)}',
      )
      .join(';');
  return '${_coordinateCacheKey(originLatitude)},${_coordinateCacheKey(originLongitude)}|$destinationKey';
}

String _coordinateCacheKey(double? value) =>
    value?.toStringAsFixed(6) ?? 'none';

class _MapProviderLookupFailure implements Exception {
  const _MapProviderLookupFailure();
}
