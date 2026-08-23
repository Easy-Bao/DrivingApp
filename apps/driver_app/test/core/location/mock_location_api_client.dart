import 'package:shared_core/shared_core.dart';

class MockLocationApiClient implements LocationApiClient {
  @override
  Future<PlaceModel> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    return PlaceModel(
      id: 'mock_1',
      name: 'Central Plaza',
      fullAddress: '123 Main Street',
      latitude: lat,
      longitude: lng,
    );
  }

  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLat,
    double? userLng,
  }) async {
    return {
      'places': [
        {
          'id': 'mock_1',
          'name': '$query Mall',
          'fullAddress': '456 Commercial Ave',
          'latitude': userLat ?? 7.8242,
          'longitude': userLng ?? 123.4350,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  }) async {
    return {
      'places': [
        {
          'id': 'mock_nearby_1',
          'name': 'City Park',
          'fullAddress': '789 Park Blvd',
          'latitude': lat,
          'longitude': lng,
        },
      ],
    };
  }

  @override
  Future<RouteModel> getRoute({required Map<String, dynamic> body}) async {
    return const RouteModel(
      polylinePoints: [
        [123.4350, 7.8242],
        [123.4400, 7.8300],
      ],
      distanceKm: 4.5,
      durationSeconds: 720,
      summary: 'Fastest route',
    );
  }

  @override
  Future<Map<String, dynamic>> getTravelMatrix({
    required Map<String, dynamic> body,
  }) async {
    final destinations = body['destinations'] as List<dynamic>? ?? [];
    return {
      'distances_km': List<double>.filled(destinations.length, 1.0),
      'durationsMin': List<double>.filled(destinations.length, 3.0),
    };
  }
}
