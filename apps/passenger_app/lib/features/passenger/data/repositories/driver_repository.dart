import 'package:core_models/core_models.dart';
import 'package:passenger_app/src/rust/api/driver_api.dart' as rust_api;
import 'package:fixtures/fixtures.dart';




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

class RustDriverRepository implements DriverRepository {
  @override
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    try {
      final rustDrivers = await rust_api.findNearbyDrivers(
        passengerLat: lat,
        passengerLng: lng,
      );
      return rustDrivers
          .map(
            (d) => DriverModel(
              id: d.id,
              name: d.name,
              vehicleType: d.vehicleType,
              plateNumber: d.plateNumber,
              rating: d.rating,
              lat: d.lat,
              lng: d.lng,
              distanceKm: d.distanceKm,
              etaMinutes: d.etaMinutes,
              score: d.score,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

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
