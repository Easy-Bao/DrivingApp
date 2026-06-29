import 'package:core_models/core_models.dart';
import 'package:location_service/location_service.dart';
import 'package:fixtures/fixtures.dart';

/**
 * Fixture-backed implementation of [DriverRepository].
 * Resolves nearby drivers using static mock assets.
 */
class FixtureDriverRepository implements DriverRepository {
  @override
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    await Future.delayed(const Duration(seconds: 2)); 
    final rawDrivers = MockData.getNearbyDrivers(lat: lat, lng: lng);
    return rawDrivers
        .map(
          (d) => DriverModel(
            id: d['id'] as String,
            name: d['name'] as String,
            vehicleType: d['vehicleType'] as String,
            plateNumber: d['plateNumber'] as String,
            rating: d['rating'] as double,
            lat: d['lat'] as double,
            lng: d['lng'] as double,
            distanceKm: d['distanceKm'] as double,
            etaMinutes: (d['etaMinutes'] as num).toDouble(),
            score: d['score'] as double,
          ),
        )
        .toList();
  }
}

/**
 * Dart concrete implementation of [DriverRepository].
 * Delegates matching calculations to the shared [DriverMatchingService].
 */
class LocalDriverRepository implements DriverRepository {
  @override
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    try {
      return DriverMatchingService.findNearbyDrivers(lat, lng);
    } catch (_) {
      return [];
    }
  }
}

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

/**
 * API-backed implementation of [DriverRepository].
 * Designed to interact directly with backend server endpoints.
 */
// ignore: unused_element — will be used when backend is integrated
class _ApiDriverRepository implements DriverRepository {
  // final HttpClient _httpClient;
  // _ApiDriverRepository(this._httpClient);

  @override
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    // final response = await _httpClient.get('/passenger/drivers/nearby?lat=$lat&lng=$lng');
    // return (response.data['drivers'] as List).map(DriverModel.fromJson).toList();
    throw UnimplementedError('Backend not yet integrated');
  }
}
