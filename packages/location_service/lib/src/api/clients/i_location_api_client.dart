import 'package:core_models/core_models.dart';

abstract class ILocationApiClient {
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLat,
    double? userLng,
  });

  Future<PlaceModel> reverseGeocode({required double lat, required double lng});

  Future<Map<String, dynamic>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  });

  Future<RouteModel> getRoute({required Map<String, dynamic> body});
}
