/// Pure Dart Mapbox geocoding and routing implementation.
library;
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:core_models/core_models.dart';
import 'map_native_service.dart';

/**
 * Concrete implementation of [MapNativeService] invoking Mapbox APIs directly over HTTP.
 * This class eliminates FFI dependencies by implementing the geocoding, reverse-geocoding,
 * routing, and mathematical computations in pure Dart.
 */
class MapNativeServiceImpl implements MapNativeService {
  /**
   * Helper method to convert degrees to radians.
   */
  static double _toRadians(double degree) {
    return degree * math.pi / 180.0;
  }

  /**
   * Calculates the great-circle distance between two points in kilometers.
   */
  static double calculateHaversine(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double haversineA = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLng / 2.0) * math.sin(dLng / 2.0);

    final double haversineC = 2.0 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
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
    if (query.trim().isEmpty) return [];

    final Map<String, String> queryParameters = {
      'access_token': token,
      'limit': '8',
      'language': 'en',
    };

    if (proximityLat != null && proximityLng != null) {
      final double latOffset = 50.0 / 111.0;
      final double lngOffset = 50.0 / (111.0 * math.cos(_toRadians(proximityLat)));

      final double minLng = proximityLng - lngOffset;
      final double minLat = proximityLat - latOffset;
      final double maxLng = proximityLng + lngOffset;
      final double maxLat = proximityLat + latOffset;

      queryParameters['proximity'] = '$proximityLng,$proximityLat';
      queryParameters['bbox'] = '$minLng,$minLat,$maxLng,$maxLat';
    }

    try {
      final Uri uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/$query.json',
        queryParameters,
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> features = data['features'] ?? [];
      final List<PlaceModel> results = [];

      for (final f in features) {
        final List<dynamic> center = f['center'] ?? [0.0, 0.0];
        final double placeLng = (center.isNotEmpty ? center[0] : 0.0) as double;
        final double placeLat = (center.length > 1 ? center[1] : 0.0) as double;

        double? distanceKm;
        if (userLat != null && userLng != null) {
          distanceKm = calculateHaversine(userLat, userLng, placeLat, placeLng);
        }

        final Map<String, dynamic>? properties = f['properties'] as Map<String, dynamic>?;
        final String? category = properties?['category'] as String?;

        results.add(PlaceModel(
          id: (f['id'] ?? '') as String,
          name: (f['text'] ?? '') as String,
          fullAddress: (f['place_name'] ?? '') as String,
          latitude: placeLat,
          longitude: placeLng,
          category: category,
          distanceKm: distanceKm,
        ));
      }

      return results;
    } catch (error) {
      return [];
    }
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
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> features = data['features'] ?? [];
      if (features.isEmpty) return null;

      final formattedAddress = features.first;
      final Map<String, dynamic>? properties = f['properties'] as Map<String, dynamic>?;
      final String? category = properties?['category'] as String?;

      return PlaceModel(
        id: (f['id'] ?? '') as String,
        name: (f['text'] ?? '') as String,
        fullAddress: (f['place_name'] ?? '') as String,
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
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> routes = data['routes'] ?? [];
      if (routes.isEmpty) return null;

      final route = routes.first;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final List<dynamic> coordinates = geometry['coordinates'] ?? [];
      final List<List<double>> points = coordinates.map<List<double>>((c) {
        final List<dynamic> coord = c as List<dynamic>;
        return [(coord[0] as num).toDouble(), (coord[1] as num).toDouble()]; // [lng, lat]
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
  }) async {
    final Map<String, String> queryParameters = {
      'radius': '2000',
      'limit': '50',
      'layers': 'poi_label',
      'access_token': token,
    };

    try {
      final Uri uri = Uri.https(
        'api.mapbox.com',
        '/v4/mapbox.mapbox-streets-v8/tilequery/$lng,$lat.json',
        queryParameters,
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> features = data['features'] ?? [];
      final List<PlaceModel> results = [];

      for (final f in features) {
        final Map<String, dynamic>? geom = f['geometry'] as Map<String, dynamic>?;
        final Map<String, dynamic>? props = f['properties'] as Map<String, dynamic>?;

        if (geom != null && props != null) {
          final List<dynamic> coords = geom['coordinates'] ?? [0.0, 0.0];
          final double pLng = (coords.isNotEmpty ? coords[0] : 0.0) as double;
          final double pLat = (coords.length > 1 ? coords[1] : 0.0) as double;

          final String name = (props['name'] ?? 'Unknown') as String;
          final String category = (props['type'] ?? 'poi') as String;
          final Map<String, dynamic>? tilequery = props['tilequery'] as Map<String, dynamic>?;
          final double distanceM = (tilequery?['distance'] ?? 0.0) as double;

          if (name.trim().isEmpty || name == 'Unknown') {
            continue;
          }

          results.add(PlaceModel(
            id: 'poi_${pLat}_$pLng',
            name: name,
            fullAddress: '$name, $category',
            latitude: pLat,
            longitude: pLng,
            category: category,
            distanceKm: distanceM / 1000.0,
          ));
        }
      }

      results.sort((a, b) {
        final double distA = a.distanceKm ?? double.maxFinite;
        final double distB = b.distanceKm ?? double.maxFinite;
        return distA.compareTo(distB);
      });

      return results;
    } catch (error) {
      return [];
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
