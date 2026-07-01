import 'package:core_models/core_models.dart';
import 'package:location_service/location_service.dart';
import 'package:fixtures/fixtures.dart';

import 'package:driver_app/core/services/driver_api_service.dart';

/**
 * Concrete implementation of [RideRepository] delegating computations to shared services.
 * Invokes shared algorithms for fare calculation and route optimization.
 */
class RideRepositoryImpl implements RideRepository {
  @override
  Future<FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
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
    return RouteOptimizationService.calculateOptimalRoute(
      startLat: startLat,
      startLng: startLng,
      waypoints: waypoints,
    );
  }
}

/**
 * Fixture-backed implementation of [RideRepository].
 * Provides mock fare and optimized route sequences using static assets.
 */
class FixtureRideRepository implements RideRepository {
  @override
  Future<FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final base = MockData.fareBase;
    final distCharge = distanceKm * MockData.fareDistanceRate;
    final timeCharge = durationMinutes * MockData.fareTimeRate;
    final surge = MockData.fareSurge;
    return FareResult(
      baseFare: base,
      distanceCharge: distCharge,
      timeCharge: timeCharge,
      surgeCharge: surge,
      totalFare: base + distCharge + timeCharge + surge,
    );
  }

  @override
  Future<RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return RouteSequenceResult(
      optimalSequence: waypoints,
      totalDistanceKm: MockData.optimizedDistanceKm,
    );
  }
}

/**
 * API-backed implementation of [RideRepository].
 * Designed to interact directly with backend server endpoints.
 */
class ApiRideRepository implements RideRepository {
  @override
  Future<FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    final fare = await DriverApiService.fetchFareEstimate(
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
    // Keep local route optimization or implement if backend endpoint is created.
    return RouteOptimizationService.calculateOptimalRoute(
      startLat: startLat,
      startLng: startLng,
      waypoints: waypoints,
    );
  }
}
