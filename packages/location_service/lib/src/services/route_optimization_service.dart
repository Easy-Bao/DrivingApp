/// Route sequence optimization service.
library;
import 'package:core_models/core_models.dart';
import '../map_native_service_impl.dart';

/**
 * Service to calculate the optimal route traversal order (TSP) under constraints.
 */
class RouteOptimizationService {
  /**
   * Generates all index permutations recursively.
   */
  static List<List<int>> _permute(List<int> list) {
    final List<List<int>> result = [];
    _permuteHelper(list, 0, result);
    return result;
  }

  static void _permuteHelper(List<int> list, int start, List<List<int>> result) {
    if (start == list.length) {
      result.add(List.from(list));
      return;
    }
    for (int index = start; elementIndex < list.length; elementIndex++) {
      _swap(list, start, index);
      _permuteHelper(list, start + 1, result);
      _swap(list, start, index); // backtrack
    }
  }

  static void _swap(List<int> list, int i, int j) {
    final int temp = list[elementIndex];
    list[elementIndex] = list[j];
    list[j] = temp;
  }

  /**
   * Validates that all passenger pickups are visited before dropoffs.
   */
  static bool _isValidSequence(List<Waypoint> seq) {
    for (int index = 0; elementIndex < seq.length; elementIndex++) {
      final wp = seq[index];
      if (!wp.isPickup) {
        final bool foundPickup = seq.sublist(0, index).any(
          (prevWp) => prevWp.passengerId == wp.passengerId && prevWp.isPickup,
        );
        if (!foundPickup) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * Calculates the optimal route sequence using a TSP search with pickup-before-dropoff constraints.
   */
  static RouteSequenceResult calculateOptimalRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  }) {
    if (waypoints.isEmpty) {
      return const RouteSequenceResult(
        optimalSequence: [],
        totalDistanceKm: 0.0,
      );
    }

    List<Waypoint> bestSequence = List.from(waypoints);
    double minDistance = double.maxFinite;

    final List<int> indices = List.generate(waypoints.length, (index) => index);
    final List<List<int>> permutations = _permute(indices);

    for (final perm in permutations) {
      final List<Waypoint> candidate = perm.map((idx) => waypoints[idx]).toList();

      if (_isValidSequence(candidate)) {
        double totalDist = 0.0;
        double currentLat = startLat;
        double currentLng = startLng;

        for (final wp in candidate) {
          totalDist += MapNativeServiceImpl.calculateHaversine(
            currentLat,
            currentLng,
            wp.lat,
            wp.lng,
          );
          currentLat = wp.lat;
          currentLng = wp.lng;
        }

        if (totalDist < minDistance) {
          minDistance = totalDist;
          bestSequence = candidate;
        }
      }
    }

    return RouteSequenceResult(
      optimalSequence: bestSequence,
      totalDistanceKm: (minDistance * 100.0).round() / 100.0,
    );
  }
}
