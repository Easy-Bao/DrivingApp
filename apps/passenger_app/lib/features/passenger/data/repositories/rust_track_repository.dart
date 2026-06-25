import 'package:passenger_app/core/services/map_provider.dart';
import 'package:core_models/core_models.dart';
import 'package:fixtures/fixtures.dart';
import 'package:flutter/foundation.dart';


/**
 * Rust-backed track and route calculation repository adapter.
 *
 * This repository implements [TrackRepository] by fetching real-world road-snapped
 * route coordinates using [MapProvider.getRoute].
 *
 * **Lifecycle & Execution Flow:**
 * Route snapping begins when the presentation layer requests a snap-to-road polyline for route
 * visualization. The repository delegates this query by calling [getRoutePolyline], which
 * initiates an asynchronous FFI request to the Rust Mapbox routing wrapper. If a valid route
 * is calculated by the Rust service, the coordinates list is returned. If the FFI lookup fails,
 * times out, or encounters a network issue, the repository intercepts the exception, logs it,
 * and generates a straight-line interpolation of the coordinates as a fallback to ensure the
 * map route layer displays successfully.
 *
 * **State & Concurrency:**
 * Route optimization executes asynchronously on the Rust background thread pool.
 */
class RustTrackRepository implements TrackRepository {
  
  @override
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final route = await MapProvider.getRoute(startLat, startLng, endLat, endLng);
      if (route != null && route.polylinePoints.isNotEmpty) {
        return route.polylinePoints;
      }
      return _generateFallbackRoute(startLat, startLng, endLat, endLng);
    } catch (e) {
      debugPrint('RustTrackRepository.getRoutePolyline failed: $e');
      return _generateFallbackRoute(startLat, startLng, endLat, endLng);
    }
  }

  /**
   * Generates a straight line interpolation of 5 coordinates if the real route lookup fails.
   */
  List<List<double>> _generateFallbackRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return MockData.interpolateRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
  }
}
