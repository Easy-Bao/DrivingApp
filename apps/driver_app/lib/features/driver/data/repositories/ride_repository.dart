import 'package:core_models/core_models.dart';
import 'package:driver_app/src/rust/api/fare_api.dart' as fare_api;
import 'package:driver_app/src/rust/models/route_models.dart' as rust_route;
import 'package:fixtures/fixtures.dart';

class RideRepositoryImpl implements RideRepository {
  @override
  Future<FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    final rustFare = await fare_api.computeFareDefault(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
    return FareResult(
      baseFare: rustFare.baseFare,
      distanceCharge: rustFare.distanceCharge,
      timeCharge: rustFare.timeCharge,
      surgeCharge: rustFare.surgeCharge,
      totalFare: rustFare.totalFare,
    );
  }

  @override
  Future<RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  }) async {
    final rustWaypoints = waypoints
        .map(
          (w) => rust_route.Waypoint(
            id: w.id,
            name: w.name,
            lat: w.lat,
            lng: w.lng,
            isPickup: w.isPickup,
            passengerId: w.passengerId,
          ),
        )
        .toList();

    final rustResult = await fare_api.calculateOptimalRoute(
      startLat: startLat,
      startLng: startLng,
      waypoints: rustWaypoints,
    );

    return RouteSequenceResult(
      optimalSequence: rustResult.optimalSequence
          .map(
            (w) => Waypoint(
              id: w.id,
              name: w.name,
              lat: w.lat,
              lng: w.lng,
              isPickup: w.isPickup,
              passengerId: w.passengerId,
            ),
          )
          .toList(),
      totalDistanceKm: rustResult.totalDistanceKm,
    );
  }
}

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
