import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:core_models/core_models.dart';
import 'package:location_service/src/features/map/domain/repositories/map_native_service.dart';

class MapNativeServiceImpl implements MapNativeService {
  final Dio _clientDio;
  final String _mapboxToken;

  MapNativeServiceImpl({required String token, Dio? dio})
      : _mapboxToken = token,
        _clientDio = dio ?? Dio();

  static double _toRadians(double degree) => degree * math.pi / 180.0;

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

    return earthRadiusKm * 2.0 * math.asin(math.sqrt(haversineA));
  }

  // Normalises Dio's dual response.data type — either already-parsed Map or a
  // raw JSON string depending on response content-type headers.
  Map<String, dynamic> _parseResponseBody(dynamic responseData) {
    if (responseData is Map<String, dynamic>) return responseData;
    return jsonDecode(responseData.toString()) as Map<String, dynamic>;
  }

  // Maps a single Mapbox GeoJSON feature to a PlaceModel.  Returns null when
  // the feature lacks a usable name or has malformed coordinates.
  PlaceModel? _parseFeatureToPlace(
    dynamic featureJson, {
    double? refLat,
    double? refLng,
    String? defaultCategory,
  }) {
    if (featureJson is! Map<String, dynamic>) return null;

    final List<dynamic> center = featureJson['center'] ?? const [0.0, 0.0];
    final double placeLng =
        center.isNotEmpty ? (center[0] as num).toDouble() : 0.0;
    final double placeLat =
        center.length > 1 ? (center[1] as num).toDouble() : 0.0;

    final String name =
        (featureJson['text'] ?? featureJson['place_name'] ?? '') as String;
    if (name.trim().isEmpty) return null;

    final Map<String, dynamic>? properties =
        featureJson['properties'] as Map<String, dynamic>?;
    final String? category =
        properties?['category'] as String? ?? defaultCategory;

    double? distanceKm;
    if (refLat != null && refLng != null) {
      distanceKm = calculateHaversine(refLat, refLng, placeLat, placeLng);
    }

    return PlaceModel(
      id: (featureJson['id'] ?? 'geo_${placeLat}_$placeLng') as String,
      name: name,
      fullAddress: (featureJson['place_name'] ?? '') as String,
      latitude: placeLat,
      longitude: placeLng,
      category: category,
      distanceKm: distanceKm,
    );
  }

  @override
  Future<List<PlaceModel>> searchPlaces({
    required String query,
    double? proximityLat,
    double? proximityLng,
    double? userLat,
    double? userLng,
  }) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    // Generate a small set of normalised query variants so dotted abbreviations
    // (e.g. "J.H") match both "J H" and "JH" in Mapbox's fuzzy index.
    final String spaceNormalised = trimmedQuery
        .replaceAll(RegExp(r'\.+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final String alphanumericOnly =
        trimmedQuery.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();

    final Set<String> queryVariations = {trimmedQuery};
    if (spaceNormalised.isNotEmpty && spaceNormalised != trimmedQuery) {
      queryVariations.add(spaceNormalised);
    }
    if (alphanumericOnly.isNotEmpty &&
        alphanumericOnly != trimmedQuery &&
        alphanumericOnly.length >= 2) {
      queryVariations.add(alphanumericOnly);
    }

    final Map<String, String> baseParams = {
      'access_token': _mapboxToken,
      'limit': '10',
      'language': 'en',
      'autocomplete': 'true',
      'fuzzyMatch': 'true',
    };

    if (proximityLat != null && proximityLng != null) {
      baseParams['proximity'] = '$proximityLng,$proximityLat';
    }

    // Fire all query variation requests in parallel — P50 latency drops from
    // ~2–4s (sequential) to ~600–900ms (parallel).
    final List<List<PlaceModel>> variantResults = await Future.wait(
      queryVariations.map((variantQuery) async {
        try {
          final Uri uri = Uri.https(
            'api.mapbox.com',
            '/geocoding/v5/mapbox.places/${Uri.encodeComponent(variantQuery)}.json',
            baseParams,
          );
          final response = await _clientDio.getUri(uri);
          if (response.statusCode != 200) {
            dev.log(
              'searchPlaces: Mapbox returned ${response.statusCode} for variant "$variantQuery"',
              name: 'MapNativeServiceImpl',
            );
            return <PlaceModel>[];
          }

          final Map<String, dynamic> data = _parseResponseBody(response.data);
          final List<dynamic> features = data['features'] ?? const [];

          return features
              .map(
                (feature) => _parseFeatureToPlace(
                  feature,
                  refLat: userLat,
                  refLng: userLng,
                ),
              )
              .whereType<PlaceModel>()
              .toList();
        } on DioException catch (dioError) {
          dev.log(
            'searchPlaces: network error for variant "$variantQuery" — ${dioError.message}',
            name: 'MapNativeServiceImpl',
            error: dioError,
          );
          return <PlaceModel>[];
        }
      }),
    );

    // Deduplicate across variant results by name key; preserve insertion order.
    final Set<String> seenDedupKeys = {};
    final List<PlaceModel> deduplicatedResults = [];

    for (final resultList in variantResults) {
      for (final place in resultList) {
        final String dedupKey =
            place.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (dedupKey.isNotEmpty && seenDedupKeys.add(dedupKey)) {
          deduplicatedResults.add(place);
        }
      }
    }

    if (userLat != null && userLng != null) {
      deduplicatedResults.sort(
        (a, b) => (a.distanceKm ?? double.maxFinite)
            .compareTo(b.distanceKm ?? double.maxFinite),
      );
    }

    return deduplicatedResults;
  }

  @override
  Future<PlaceModel?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final Uri uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/$lng,$lat.json',
        {'access_token': _mapboxToken, 'limit': '1', 'language': 'en'},
      );
      final response = await _clientDio.getUri(uri);
      if (response.statusCode != 200) {
        dev.log(
          'reverseGeocode: Mapbox returned ${response.statusCode} for ($lat, $lng)',
          name: 'MapNativeServiceImpl',
        );
        return null;
      }

      final Map<String, dynamic> data = _parseResponseBody(response.data);
      final List<dynamic> features = data['features'] ?? const [];
      if (features.isEmpty) return null;

      return _parseFeatureToPlace(
        features.first,
        refLat: lat,
        refLng: lng,
      );
    } on DioException catch (dioError) {
      dev.log(
        'reverseGeocode: network error for ($lat, $lng) — ${dioError.message}',
        name: 'MapNativeServiceImpl',
        error: dioError,
      );
      return null;
    }
  }

  @override
  Future<RouteModel?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final Uri uri = Uri.https(
        'api.mapbox.com',
        '/directions/v5/mapbox/driving/$originLng,$originLat;$destLng,$destLat',
        {
          'access_token': _mapboxToken,
          'geometries': 'geojson',
          'overview': 'full',
        },
      );
      final response = await _clientDio.getUri(uri);
      if (response.statusCode != 200) {
        dev.log(
          'getRoute: Mapbox returned ${response.statusCode}',
          name: 'MapNativeServiceImpl',
        );
        return null;
      }

      final Map<String, dynamic> data = _parseResponseBody(response.data);
      final List<dynamic> routes = data['routes'] ?? const [];
      if (routes.isEmpty) return null;

      final Map<String, dynamic> route = routes.first as Map<String, dynamic>;
      final Map<String, dynamic> geometry =
          route['geometry'] as Map<String, dynamic>;
      final List<dynamic> coordinates = geometry['coordinates'] ?? const [];

      final List<List<double>> points = coordinates.map<List<double>>((coord) {
        final List<dynamic> coordList = coord as List<dynamic>;
        return [
          (coordList[0] as num).toDouble(),
          (coordList[1] as num).toDouble(),
        ];
      }).toList();

      final List<dynamic>? legs = route['legs'] as List<dynamic>?;
      final String routeSummary = legs != null && legs.isNotEmpty
          ? ((legs.first as Map<String, dynamic>)['summary'] ?? '') as String
          : '';

      return RouteModel(
        polylinePoints: points,
        distanceKm: (route['distance'] as num).toDouble() / 1000.0,
        durationSeconds: (route['duration'] as num).toDouble().round(),
        summary: routeSummary,
      );
    } on DioException catch (dioError) {
      dev.log(
        'getRoute: network error — ${dioError.message}',
        name: 'MapNativeServiceImpl',
        error: dioError,
      );
      return null;
    }
  }

  @override
  Future<List<PlaceModel>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  }) async {
    // Category batches are paged to limit per-request Mapbox credit spend.
    // Page 1 covers high-value everyday destinations; subsequent pages extend
    // into specialist categories.  Each batch fires in parallel via Future.wait.
    const List<List<String>> categoryPages = [
      ['restaurant', 'supermarket', 'hospital', 'bank', 'gas_station'],
      ['school', 'college', 'pharmacy', 'hotel', 'mall'],
      ['church', 'park', 'police', 'market', 'gym'],
      ['cafe', 'bakery', 'terminal', 'resort', 'hardware'],
    ];

    final int pageIndex = (page - 1).clamp(0, categoryPages.length - 1);
    final List<String> categoriesForPage = categoryPages[pageIndex];

    final List<List<PlaceModel>> categoryResults = await Future.wait(
      categoriesForPage.map(
        (category) => _fetchPoisForCategory(
          lat: lat,
          lng: lng,
          category: category,
        ),
      ),
    );

    // Merge parallel results, deduplicating by normalised name key.
    final Set<String> seenKeys = {};
    final List<PlaceModel> combinedPois = [];

    for (final poiList in categoryResults) {
      for (final poi in poiList) {
        final String key =
            poi.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (key.isNotEmpty && seenKeys.add(key)) {
          combinedPois.add(poi);
        }
      }
    }

    combinedPois.sort(
      (a, b) => (a.distanceKm ?? double.maxFinite)
          .compareTo(b.distanceKm ?? double.maxFinite),
    );

    return combinedPois;
  }

  Future<List<PlaceModel>> _fetchPoisForCategory({
    required double lat,
    required double lng,
    required String category,
  }) async {
    try {
      final Uri uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/${Uri.encodeComponent(category)}.json',
        {
          'access_token': _mapboxToken,
          'proximity': '$lng,$lat',
          'types': 'poi',
          'limit': '5',
          'language': 'en',
        },
      );
      final response = await _clientDio.getUri(uri);
      if (response.statusCode != 200) {
        dev.log(
          '_fetchPoisForCategory: Mapbox returned ${response.statusCode} for "$category"',
          name: 'MapNativeServiceImpl',
        );
        return const [];
      }

      final Map<String, dynamic> data = _parseResponseBody(response.data);
      final List<dynamic> features = data['features'] ?? const [];

      return features
          .map(
            (feature) => _parseFeatureToPlace(
              feature,
              refLat: lat,
              refLng: lng,
              defaultCategory: category,
            ),
          )
          .whereType<PlaceModel>()
          .where((poi) => poi.distanceKm != null && poi.distanceKm! <= 5.0)
          .toList();
    } on DioException catch (dioError) {
      dev.log(
        '_fetchPoisForCategory: network error for "$category" — ${dioError.message}',
        name: 'MapNativeServiceImpl',
        error: dioError,
      );
      return const [];
    }
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
