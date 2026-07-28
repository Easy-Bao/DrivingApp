import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:core_models/core_models.dart';
import 'package:location_service/src/features/map/domain/repositories/map_native_service.dart';

class MapNativeServiceImpl implements MapNativeService {
  final Dio _clientDio;

  MapNativeServiceImpl({Dio? dio}) : _clientDio = dio ?? Dio();

  static double _toRadians(double degree) {
    return degree * math.pi / 180.0;
  }

  static double calculateHaversine(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double haversineA =
        math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2.0) *
            math.sin(dLng / 2.0);

    final double haversineC = 2.0 * math.asin(math.sqrt(haversineA));
    return earthRadiusKm * haversineC;
  }

  @override
  Future<List<PlaceModel>> searchPlaces({
    required String token,
    required String query,
    double? proximityLat,
    double? proximityLng,
    double? userLat,
    double? userLng,
  }) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final String cleanedQuery = trimmedQuery
        .replaceAll(RegExp(r'\.+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final String noDotNoSpaceQuery = trimmedQuery
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .trim();

    final Set<String> queryVariations = {trimmedQuery};
    if (cleanedQuery.isNotEmpty && cleanedQuery != trimmedQuery) {
      queryVariations.add(cleanedQuery);
    }
    if (noDotNoSpaceQuery.isNotEmpty &&
        noDotNoSpaceQuery != trimmedQuery &&
        noDotNoSpaceQuery.length >= 2) {
      queryVariations.add(noDotNoSpaceQuery);
    }

    final List<PlaceModel> combinedResults = [];
    final Set<String> seenIdsOrNames = {};

    for (final q in queryVariations) {
      final Map<String, String> queryParameters = {
        'access_token': token,
        'limit': '10',
        'language': 'en',
        'autocomplete': 'true',
        'fuzzyMatch': 'true',
      };

      if (proximityLat != null && proximityLng != null) {
        queryParameters['proximity'] = '$proximityLng,$proximityLat';
      }

      try {
        final Uri uri = Uri.https(
          'api.mapbox.com',
          '/geocoding/v5/mapbox.places/${Uri.encodeComponent(q)}.json',
          queryParameters,
        );
        final response = await _clientDio.getUri(uri);
        if (response.statusCode != 200) {
          continue;
        }

        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data.toString());
        final List<dynamic> features = data['features'] ?? [];

        for (final f in features) {
          final List<dynamic> center = f['center'] ?? [0.0, 0.0];
          final double placeLng = center.isNotEmpty
              ? (center[0] as num).toDouble()
              : 0.0;
          final double placeLat = center.length > 1
              ? (center[1] as num).toDouble()
              : 0.0;

          final String id = (f['id'] ?? '') as String;
          final String name = (f['text'] ?? (f['place_name'] ?? '')) as String;
          final String fullAddress = (f['place_name'] ?? '') as String;

          final String dedupKey =
              name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (seenIdsOrNames.contains(id) ||
              (dedupKey.isNotEmpty && seenIdsOrNames.contains(dedupKey))) {
            continue;
          }
          if (id.isNotEmpty) seenIdsOrNames.add(id);
          if (dedupKey.isNotEmpty) seenIdsOrNames.add(dedupKey);

          double? distanceKm;
          if (userLat != null && userLng != null) {
            distanceKm =
                calculateHaversine(userLat, userLng, placeLat, placeLng);
          }

          final Map<String, dynamic>? properties =
              f['properties'] as Map<String, dynamic>?;
          final String? category = properties?['category'] as String?;

          combinedResults.add(
            PlaceModel(
              id: id,
              name: name,
              fullAddress: fullAddress,
              latitude: placeLat,
              longitude: placeLng,
              category: category,
              distanceKm: distanceKm,
            ),
          );
        }
      } catch (_) {
        // Continue to next variation on network error
      }
    }

    combinedResults.sort((a, b) {
      final double distA = a.distanceKm ?? double.maxFinite;
      final double distB = b.distanceKm ?? double.maxFinite;
      return distA.compareTo(distB);
    });

    return combinedResults;
  }

  @override
  Future<PlaceModel?> reverseGeocode({
    required String token,
    required double lat,
    required double lng,
  }) async {
    final Map<String, String> queryParameters = {
      'access_token': token,
      'limit': '1',
      'language': 'en',
    };

    try {
      final Uri uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/$lng,$lat.json',
        queryParameters,
      );
      final response = await _clientDio.getUri(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : jsonDecode(response.data.toString());
      final List<dynamic> features = data['features'] ?? [];
      if (features.isEmpty) return null;

      final Map<String, dynamic> targetFeature =
          features.first as Map<String, dynamic>;
      final Map<String, dynamic>? properties =
          targetFeature['properties'] as Map<String, dynamic>?;
      final String? category = properties?['category'] as String?;

      return PlaceModel(
        id: (targetFeature['id'] ?? '') as String,
        name: (targetFeature['text'] ?? '') as String,
        fullAddress: (targetFeature['place_name'] ?? '') as String,
        latitude: lat,
        longitude: lng,
        category: category,
      );
    } catch (error) {
      return null;
    }
  }

  @override
  Future<RouteModel?> getRoute({
    required String token,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final Map<String, String> queryParameters = {
      'access_token': token,
      'geometries': 'geojson',
      'overview': 'full',
    };

    try {
      final Uri uri = Uri.https(
        'api.mapbox.com',
        '/directions/v5/mapbox/driving/$originLng,$originLat;$destLng,$destLat',
        queryParameters,
      );
      final response = await _clientDio.getUri(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : jsonDecode(response.data.toString());
      final List<dynamic> routes = data['routes'] ?? [];
      if (routes.isEmpty) return null;

      final route = routes.first;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final List<dynamic> coordinates = geometry['coordinates'] ?? [];
      final List<List<double>> points = coordinates.map<List<double>>((c) {
        final List<dynamic> coord = c as List<dynamic>;
        return [(coord[0] as num).toDouble(), (coord[1] as num).toDouble()];
      }).toList();

      final List<dynamic>? legs = route['legs'] as List<dynamic>?;
      String summary = '';
      if (legs != null && legs.isNotEmpty) {
        final leg = legs.first as Map<String, dynamic>;
        summary = (leg['summary'] ?? '') as String;
      }

      return RouteModel(
        polylinePoints: points,
        distanceKm: (route['distance'] as num).toDouble() / 1000.0,
        durationSeconds: (route['duration'] as num).toDouble().round(),
        summary: summary,
      );
    } catch (error) {
      return null;
    }
  }

  @override
  Future<List<PlaceModel>> getNearbyPois({
    required String token,
    required double lat,
    required double lng,
    int page = 1,
  }) async {
    final List<PlaceModel> combinedPois = [];
    final Set<String> seenKeys = {};

    final List<List<String>> categoryPages = [
      ['school', 'college', 'hospital', 'resort', 'hotel', 'bank', 'restaurant', 'gas', 'supermarket', 'park'],
      ['church', 'mall', 'police', 'market', 'cemetery', 'store', 'agency', 'canteen', 'barber', 'laundry'],
      ['cafe', 'gym', 'hardware', 'pharmacy', 'bakery', 'office', 'station', 'terminal', 'government'],
    ];

    final int targetPageIndex = (page - 1).clamp(0, categoryPages.length - 1);
    final List<String> searchCategories = categoryPages[targetPageIndex];

    for (final cat in searchCategories) {
      final Map<String, String> geoParams = {
        'access_token': token,
        'proximity': '$lng,$lat',
        'limit': '10',
        'language': 'en',
      };

      try {
        final Uri uri = Uri.https(
          'api.mapbox.com',
          '/geocoding/v5/mapbox.places/${Uri.encodeComponent(cat)}.json',
          geoParams,
        );
        final response = await _clientDio.getUri(uri);
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : jsonDecode(response.data.toString());
          final List<dynamic> features = data['features'] ?? [];

          for (final f in features) {
            final List<dynamic> center = f['center'] ?? [0.0, 0.0];
            final double pLng = center.isNotEmpty ? (center[0] as num).toDouble() : 0.0;
            final double pLat = center.length > 1 ? (center[1] as num).toDouble() : 0.0;

            final String name = (f['text'] ?? (f['place_name'] ?? '')) as String;
            final String fullAddress = (f['place_name'] ?? '') as String;
            if (name.trim().isEmpty) continue;

            final double distanceKm = calculateHaversine(lat, lng, pLat, pLng);
            if (distanceKm > 5.0) continue;

            final String key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            if (seenKeys.contains(key)) continue;
            seenKeys.add(key);

            final Map<String, dynamic>? properties = f['properties'] as Map<String, dynamic>?;
            final String? category = properties?['category'] as String?;

            combinedPois.add(
              PlaceModel(
                id: (f['id'] ?? 'geo_${pLat}_$pLng') as String,
                name: name,
                fullAddress: fullAddress,
                latitude: pLat,
                longitude: pLng,
                category: category ?? cat,
                distanceKm: distanceKm,
              ),
            );
          }
        }
      } catch (_) {
        // Silently continue for category failures
      }
    }

    if (page == 1) {
      // Fetch hyper-local POIs via Tilequery API on initial page
      final Map<String, String> tileQueryParams = {
        'radius': '5000',
        'limit': '50',
        'layers': 'poi_label',
        'access_token': token,
      };

      try {
        final Uri uri = Uri.https(
          'api.mapbox.com',
          '/v4/mapbox.mapbox-streets-v8/tilequery/$lng,$lat.json',
          tileQueryParams,
        );
        final response = await _clientDio.getUri(uri);
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : jsonDecode(response.data.toString());
          final List<dynamic> features = data['features'] ?? [];

          for (final f in features) {
            final Map<String, dynamic>? geom = f['geometry'] as Map<String, dynamic>?;
            final Map<String, dynamic>? props = f['properties'] as Map<String, dynamic>?;

            if (geom != null && props != null) {
              final List<dynamic> coords = geom['coordinates'] ?? [0.0, 0.0];
              final double pLng = coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
              final double pLat = coords.length > 1 ? (coords[1] as num).toDouble() : 0.0;

              final String name = (props['name'] ?? '') as String;
              final String category = (props['type'] ?? 'poi') as String;
              if (name.trim().isEmpty || name == 'Unknown') continue;

              final double distanceKm = calculateHaversine(lat, lng, pLat, pLng);
              if (distanceKm > 5.0) continue;

              final String key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
              if (seenKeys.contains(key)) continue;
              seenKeys.add(key);

              combinedPois.add(
                PlaceModel(
                  id: 'poi_${pLat}_$pLng',
                  name: name,
                  fullAddress: '$name, $category',
                  latitude: pLat,
                  longitude: pLng,
                  category: category,
                  distanceKm: distanceKm,
                ),
              );
            }
          }
        }
      } catch (_) {
        // Ignore tilequery errors
      }
    }

    combinedPois.sort((a, b) {
      final double distA = a.distanceKm ?? double.maxFinite;
      final double distB = b.distanceKm ?? double.maxFinite;
      return distA.compareTo(distB);
    });

    return combinedPois;
  }

  @override
  Future<double> haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) async {
    return calculateHaversine(lat1, lng1, lat2, lng2);
  }
}
