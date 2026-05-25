import 'package:BaoRide/src/rust/api/fare_api.dart' as fare_api;
import 'package:BaoRide/src/rust/models/fare_models.dart' as rust_fare;
import 'package:BaoRide/src/rust/models/route_models.dart' as rust_route;

abstract class RideRepository {
  Future<rust_fare.FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  });

  Future<rust_route.RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<rust_route.Waypoint> waypoints,
  });
}

class RideRepositoryImpl implements RideRepository {
  @override
  Future<rust_fare.FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) {
    return fare_api.computeFareDefault(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  @override
  Future<rust_route.RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<rust_route.Waypoint> waypoints,
  }) {
    return fare_api.calculateOptimalRoute(
      startLat: startLat,
      startLng: startLng,
      waypoints: waypoints,
    );
  }
}

class MockRideRepository implements RideRepository {
  @override
  Future<rust_fare.FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return rust_fare.FareResult(
      baseFare: 40.0,
      distanceCharge: distanceKm * 8.0,
      timeCharge: durationMinutes * 1.0,
      surgeCharge: 0.0,
      totalFare: 40.0 + (distanceKm * 8.0) + durationMinutes,
    );
  }

  @override
  Future<rust_route.RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<rust_route.Waypoint> waypoints,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return rust_route.RouteSequenceResult(
      optimalSequence: waypoints,
      totalDistanceKm: 5.2,
    );
  }
}

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

// ignore: unused_element — will be used when backend is integrated
class _ApiRideRepository implements RideRepository {
  // final HttpClient _httpClient;
  // _ApiRideRepository(this._httpClient);

  @override
  Future<rust_fare.FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    // final response = await _httpClient.get('/ride/fare', queryParameters: {
    //   'distanceKm': distanceKm,
    //   'durationMinutes': durationMinutes,
    // });
    // return rust_fare.FareResult.fromJson(response.data);
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<rust_route.RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<rust_route.Waypoint> waypoints,
  }) async {
    // final response = await _httpClient.post('/ride/optimize', data: {
    //   'startLat': startLat,
    //   'startLng': startLng,
    //   'waypoints': waypoints.map((w) => w.toJson()).toList(),
    // });
    // return rust_route.RouteSequenceResult.fromJson(response.data);
    throw UnimplementedError('Backend not yet integrated');
  }
}
