import 'package:core_models/core_models.dart';
import 'package:fixtures/fixtures.dart';

/**
 * Fixture-backed implementation of [PassengerHomeRepository].
 * Resolves address and recent locations using static mock data assets.
 */
class FixturePassengerHomeRepository implements PassengerHomeRepository {
  @override
  Future<String> resolveAddress({
    required double lat,
    required double lng,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockData.defaultAddress;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLocations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.getRecentLocations();
  }
}

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

// ignore: unused_element — will be used when backend is integrated
/**
 * API-backed implementation of [PassengerHomeRepository].
 * Designed to fetch data directly from backend server endpoints.
 */
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
