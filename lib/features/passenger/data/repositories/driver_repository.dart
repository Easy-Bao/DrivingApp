import 'package:BaoRide/core/models/driver/driver_model.dart';
import 'package:BaoRide/src/rust/api/driver_api.dart' as rust_api;

abstract class DriverRepository {
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}

class DriverRepositoryImpl implements DriverRepository {
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
    } catch (e) {
      // Fallback or error propagation
      return [];
    }
  }
}
