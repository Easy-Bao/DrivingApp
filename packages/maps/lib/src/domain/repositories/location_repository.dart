import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';

abstract class LocationRepository {
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLat,
    double? userLng,
  });

  Future<Place> reverseGeocode({required double lat, required double lng});

  Future<Map<String, dynamic>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  });

  Future<Route> getRoute({required Map<String, dynamic> body});

  Future<Map<String, dynamic>> getTravelMatrix({
    required Map<String, dynamic> body,
  });
}
