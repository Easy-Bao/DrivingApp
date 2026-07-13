import 'package:core_models/core_models.dart';
import 'package:location_service/location_service.dart';
import 'package:driver_app/src/core/services/driver_api_service.dart';

/// API-backed implementation of [RideRepository].
/// Designed to interact directly with backend server endpoints.
class RideRepositoryImpl implements RideRepository {
  final DriverApiService _apiService;

  RideRepositoryImpl({required DriverApiService apiService})
    : _apiService = apiService;

  @override
  Future<FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    final fare = await _apiService.fetchFareEstimate(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
    if (fare != null) {
      return FareResult(
        baseFare: (fare['base_fare'] as num).toDouble(),
        distanceCharge: (fare['distance_charge'] as num).toDouble(),
        timeCharge: (fare['time_charge'] as num).toDouble(),
        surgeCharge: (fare['surge_charge'] as num).toDouble(),
        totalFare: (fare['total_fare'] as num).toDouble(),
      );
    }
    // Fallback if service unavailable
    return FareCalculationService.computeFareDefault(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  @override
  Future<RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  }) async {
    // Local route optimization calculation
    return RouteOptimizationService.calculateOptimalRoute(
      startLat: startLat,
      startLng: startLng,
      waypoints: waypoints,
    );
  }
}
