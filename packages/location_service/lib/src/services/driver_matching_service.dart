/// Proximity-based driver matching and dispatching service.
library;
import 'dart:math' as math;
import 'package:core_models/core_models.dart';
import 'package:fixtures/fixtures.dart';
import '../map_native_service_impl.dart';

/**
 * Service to simulate and match nearby drivers for ride requests.
 * Uses spatial displacement around a passenger location and sorts drivers based on distance, rating, and ETA.
 */
class DriverMatchingService {
  /**
   * Discovers and ranks 5 nearby drivers relative to the passenger's current coordinates.
   */
  static List<DriverModel> findNearbyDrivers(double passengerLat, double passengerLng) {
    final driverPool = MockData.getDriverPool();

    final List<DriverModel> drivers = [];
    final List<double> angleSteps = [0.0, 45.0, 90.0, 135.0, 180.0];
    final List<double> distanceSteps = [0.6, 1.2, 0.8, 2.1, 1.5]; // km

    for (int i = 0; i < driverPool.length; i++) {
      final poolItem = driverPool[i];
      final String id = poolItem['id'] as String;
      final String name = poolItem['name'] as String;
      final String vehicleType = poolItem['vehicleType'] as String;
      final String plateNumber = poolItem['plateNumber'] as String;
      final double rating = poolItem['rating'] as double;

      final double distKm = distanceSteps[i];
      final double angleRad = angleSteps[i] * math.pi / 180.0;

      final double latOffset = (distKm / 111.0) * math.cos(angleRad);
      final double lngOffset = (distKm / (111.0 * math.cos(passengerLat * math.pi / 180.0))) * math.sin(angleRad);

      final double dLat = passengerLat + latOffset;
      final double dLng = passengerLng + lngOffset;

      final double actualDist = MapNativeServiceImpl.calculateHaversine(passengerLat, passengerLng, dLat, dLng);
      final double etaMinutes = math.max(actualDist / 20.0 * 60.0, 1.0);

      // Score formula: 50% distance, 30% rating gap, 20% ETA
      final double score = (0.5 * actualDist) + (0.3 * (5.0 - rating)) + (0.2 * etaMinutes);

      drivers.add(DriverModel(
        id: id,
        name: name,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        rating: rating,
        lat: dLat,
        lng: dLng,
        distanceKm: actualDist,
        etaMinutes: etaMinutes,
        score: score,
      ));
    }

    drivers.sort((a, b) => a.score.compareTo(b.score));
    return drivers;
  }
}
