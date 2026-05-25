import 'package:BaoRide/core/models/driver/driver_model.dart';
import 'package:BaoRide/src/rust/api/driver_api.dart' as rust_api;

/// Contract: defines what the passenger feature needs for finding nearby drivers.
/// Neither the Bloc nor the UI ever depends on a concrete class.
abstract class DriverRepository {
  /// Returns a list of nearby available drivers for the given coordinates.
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK IMPLEMENTATION — for development and unit testing
// ─────────────────────────────────────────────────────────────────────────────

class MockDriverRepository implements DriverRepository {
  @override
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate radar scan
    return [
      DriverModel(
        id: 'drv_001',
        name: 'Xyrel T.',
        vehicleType: 'Motorcycle',
        plateNumber: 'ZDN-1234',
        rating: 4.9,
        lat: lat + 0.003,
        lng: lng - 0.002,
        distanceKm: 0.42,
        etaMinutes: 2,
        score: 0.95,
      ),
      DriverModel(
        id: 'drv_002',
        name: 'Marco D.',
        vehicleType: 'Motorcycle',
        plateNumber: 'ZDN-5678',
        rating: 4.7,
        lat: lat - 0.004,
        lng: lng + 0.003,
        distanceKm: 0.88,
        etaMinutes: 4,
        score: 0.82,
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RUST FFI IMPLEMENTATION — uses local driver-matching Rust algorithm
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// API IMPLEMENTATION — for when the Go backend WebSocket is ready
// ─────────────────────────────────────────────────────────────────────────────

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
