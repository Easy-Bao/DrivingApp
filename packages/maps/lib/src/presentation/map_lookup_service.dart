import 'dart:async';

import 'package:foundation/foundation.dart';
import 'package:maps/src/data/datasources/location_service.dart';
import 'package:maps/src/data/services/map_http_service.dart';
import 'package:maps/src/data/services/nearby_place_resolver.dart';
import 'package:maps/src/data/services/route_request_key.dart';
import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';
import 'package:maps/src/domain/failures/place_failure.dart';
import 'package:material_ui/material_ui.dart' show debugPrint;

class MapLookupService._() {
  static const double nearbyRadiusKm = 5.0;
  static const _lookupCacheTtl = Duration(seconds: 15);
  static const _routeCacheTtl = Duration(seconds: 20);
  static const _routeRetryDelay = Duration(milliseconds: 250);

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

  static void configure(MapNativeService nativeService) {
    _nativeService = nativeService;
    clearLookupCaches();
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

  static MapNativeService _requireNativeService() {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('MapProvider not initialized.');
    }
    return nativeService;
  }

  static Future<List<Place>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    if (query.trim().isEmpty) return [];

    final nativeService = _requireNativeService();
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

        return switch (result) {
          Err(:final failure) => () {
            debugPrint(
              'MapProvider.searchPlaces failure: ${failure.runtimeType}',
            );
            throw const _MapLookupFailure();
          }(),
          Ok(value: final places) =>
            places
                .where((p) {
                  final distance = p.distanceKm;
                  return distance == null || distance <= 30.0;
                })
                .toList(growable: false),
        };
      });
    } on _MapLookupFailure {
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
    final nativeService = _requireNativeService();

    try {
      final result = await nativeService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
      return switch (result) {
        Ok(:final value) => value,
        Err(:final failure) => () {
          debugPrint(
            'MapProvider.getPlaceFromCoordinates failure: ${failure.runtimeType}',
          );
          return null;
        }(),
      };
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
    final nativeService = _requireNativeService();

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
        final (route, retryable) = switch (result) {
          Ok(:final value) => (value, false),
          Err(:final failure) => () {
            debugPrint('MapProvider.getRoute failure: ${failure.runtimeType}');
            return (null, failure is PlaceNetworkError);
          }(),
        };
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
    final nativeService = _requireNativeService();
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
        return switch (result) {
          Ok(value: final distances) => distances,
          Err(:final failure) => () {
            debugPrint(
              'MapProvider.getDrivingDistances failure: ${failure.runtimeType}',
            );
            return null;
          }(),
        };
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
    final nativeService = _requireNativeService();
    final key = _nearbyRequestKey(latitude, longitude, page);
    try {
      return await _nearbyCache.getOrLoad(key, () async {
        final result = await nativeService.getNearbyPois(
          latitude: latitude,
          longitude: longitude,
          page: page,
        );
        return switch (result) {
          Err(:final failure) => () {
            debugPrint(
              'MapProvider.getNearbyPOIs failure: ${failure.runtimeType}',
            );
            throw const _MapLookupFailure();
          }(),
          Ok(value: final pois) => NearbyPlaceResolver.withinRadius(
            places: pois,
            latitude: latitude,
            longitude: longitude,
            radiusKm: nearbyRadiusKm,
          ),
        };
      });
    } on _MapLookupFailure {
      return [];
    } catch (_) {
      debugPrint('MapProvider.getNearbyPOIs error.');
      return [];
    }
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

class _MapLookupFailure implements Exception {
  const _MapLookupFailure();
}
