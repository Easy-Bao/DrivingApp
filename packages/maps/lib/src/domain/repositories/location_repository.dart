import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';

abstract class LocationRepository {
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLatitude,
    double? userLongitude,
  });

  Future<Place> reverseGeocode({
    required double latitude,
    required double longitude,
  });

  Future<Map<String, dynamic>> getNearbyPois({
    required double latitude,
    required double longitude,
    int page = 1,
  });

  Future<Route> getRoute({required Map<String, dynamic> body});

  Future<Map<String, dynamic>> getTravelMatrix({
    required Map<String, dynamic> body,
  });
}
