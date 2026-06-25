import '../models/driver_model.dart';

/**
 * Contract: defines what the passenger feature needs for finding nearby drivers.
 */
abstract class DriverRepository {
  /**
   * Returns a list of nearby available drivers for the given coordinates.
   */
  Future<List<DriverModel>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}
