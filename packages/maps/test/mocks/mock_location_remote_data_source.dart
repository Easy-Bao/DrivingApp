import 'package:maps/maps.dart';

class MockLocationRemoteDataSource implements LocationRemoteDataSource {
  @override
  Future<Place> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    return Place(
      id: 'mock_1',
      name: 'Central Plaza',
      fullAddress: '123 Main Street',
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) async {
    return {
      'places': [
        {
          'id': 'mock_1',
          'name': '$query Mall',
          'fullAddress': '456 Commercial Ave',
          'latitude': userLatitude ?? 7.8242,
          'longitude': userLongitude ?? 123.4350,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> getNearbyPois({
    required double latitude,
    required double longitude,
    int page = 1,
  }) async {
    return {
      'places': [
        {
          'id': 'mock_nearby_1',
          'name': 'City Park',
          'fullAddress': '789 Park Blvd',
          'latitude': latitude,
          'longitude': longitude,
        },
      ],
    };
  }

  @override
  Future<Route> getRoute({required Map<String, dynamic> body}) async {
    return const Route(
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
