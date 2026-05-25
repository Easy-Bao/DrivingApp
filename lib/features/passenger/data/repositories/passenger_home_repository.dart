/// Contract: what the PassengerHome feature needs from the data layer.
/// Covers location resolution and recent place history.
abstract class PassengerHomeRepository {
  /// Resolves the current address for the given coordinates.
  Future<String> resolveAddress({required double lat, required double lng});

  /// Returns the passenger's recent destinations.
  Future<List<Map<String, dynamic>>> getRecentLocations();
}

class MockPassengerHomeRepository implements PassengerHomeRepository {
  @override
  Future<String> resolveAddress({
    required double lat,
    required double lng,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'Pagadian City, Zamboanga del Sur';
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLocations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'title': 'Plaza Luz',
        'subtitle': 'San Francisco',
        'lat': 7.8275,
        'lng': 123.4365,
      },
      {
        'title': 'Robinson Supermarket',
        'subtitle': 'San Francisco',
        'lat': 7.8250,
        'lng': 123.4380,
      },
      {
        'title': "Bo's Coffee",
        'subtitle': 'San Francisco',
        'lat': 7.8295,
        'lng': 123.4358,
      },
      {
        'title': 'Gaisano Capital',
        'subtitle': 'San Francisco',
        'lat': 7.8260,
        'lng': 123.4355,
      },
    ];
  }
}

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

// ignore: unused_element — will be used when backend is integrated
class _ApiPassengerHomeRepository implements PassengerHomeRepository {
  // final HttpClient _httpClient;
  // _ApiPassengerHomeRepository(this._httpClient);

  @override
  Future<String> resolveAddress({
    required double lat,
    required double lng,
  }) async {
    // final response = await _httpClient.get('/geocode/reverse?lat=$lat&lng=$lng');
    // return response.data['address'] as String;
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLocations() async {
    // final response = await _httpClient.get('/passenger/locations/recent');
    // return List<Map<String, dynamic>>.from(response.data['locations']);
    throw UnimplementedError('Backend not yet integrated');
  }
}
