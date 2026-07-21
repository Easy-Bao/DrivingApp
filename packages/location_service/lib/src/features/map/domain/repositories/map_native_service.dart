import 'package:core_models/core_models.dart';

abstract class MapNativeService {
  
  Future<List<PlaceModel>> searchPlaces({
    required String token,
    required String query,
    double? proximityLat,
    double? proximityLng,
    double? userLat,
    double? userLng,
  });

  Future<PlaceModel?> reverseGeocode({
    required String token,
    required double lat,
    required double lng,
  });

  Future<RouteModel?> getRoute({
    required String token,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });

  Future<List<PlaceModel>> getNearbyPois({
    required String token,
    required double lat,
    required double lng,
  });

  Future<double> haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  });
}
