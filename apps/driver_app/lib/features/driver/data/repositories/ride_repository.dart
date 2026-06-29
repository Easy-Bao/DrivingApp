import 'package:core_models/core_models.dart';
import 'package:location_service/location_service.dart';
import 'package:fixtures/fixtures.dart';

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

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

/**
 * API-backed implementation of [RideRepository].
 * Designed to interact directly with backend server endpoints.
 */
// ignore: unused_element — will be used when backend is integrated
class _ApiRideRepository implements RideRepository {
  @override
  Future<FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  }) async {
    throw UnimplementedError('Backend not yet integrated');
  }
}
