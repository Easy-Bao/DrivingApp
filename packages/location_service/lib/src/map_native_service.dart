import 'package:core_models/core_models.dart';

/// Interface isolating Mapbox/native FFI operations from LocationService and MapProvider.
abstract class MapNativeService {
  /// Search for places based on a query string.
  Future<List<PlaceModel>> searchPlaces({
    required String token,
    required String query,
    double? proximityLat,
    double? proximityLng,
    double? userLat,
    double? userLng,
  });

  /// Resolve a place model from geographical coordinates.
  Future<PlaceModel?> reverseGeocode({
    required String token,
    required double lat,
    required double lng,
  });

  /// Fetch route details (polyline, distance, duration) between two locations.
  Future<RouteModel?> getRoute({
    required String token,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });

  /// Retrieve nearby points of interest within a geographical range.
  Future<List<PlaceModel>> getNearbyPois({
    required String token,
    required double lat,
    required double lng,
  });

  /// Calculate haversine distance between two coordinates.
  Future<double> haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  });
}
