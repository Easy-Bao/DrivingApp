import 'dart:math' as math;
import 'package:shared_core/shared_core.dart';

class RouteOptimizationService {
  RouteOptimizationService._();

  String get componentName => 'route-optimization';

  static double _calculateHaversine(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = (lat2 - lat1) * math.pi / 180.0;
    final double dLng = (lng2 - lng1) * math.pi / 180.0;

    final double haversineA =
        math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2.0) *
            math.sin(dLng / 2.0);

    final double haversineC = 2.0 * math.asin(math.sqrt(haversineA));
    return earthRadiusKm * haversineC;
  }

  static List<List<int>> _permute(List<int> list) {
    final List<List<int>> result = [];
    _permuteHelper(list, 0, result);
    return result;
  }

  static void _permuteHelper(
    List<int> list,
    int start,
    List<List<int>> result,
  ) {
    if (start == list.length) {
      result.add(List.from(list));
      return;
    }
    for (int index = start; index < list.length; index++) {
      _swap(list, start, index);
      _permuteHelper(list, start + 1, result);
      _swap(list, start, index);
    }
  }

  static void _swap(List<int> list, int i, int j) {
    final int temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }

  static bool _isValidSequence(List<Waypoint> seq) {
    for (int index = 0; index < seq.length; index++) {
      final wp = seq[index];
      if (!wp.isPickup) {
        final bool foundPickup = seq
            .sublist(0, index)
            .any(
              (prevWp) =>
                  prevWp.passengerId == wp.passengerId && prevWp.isPickup,
            );
        if (!foundPickup) {
          return false;
        }
      }
    }
    return true;
  }

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
      final List<Waypoint> candidate = perm
          .map((idx) => waypoints[idx])
          .toList();

      if (_isValidSequence(candidate)) {
        double totalDist = 0.0;
        double currentLat = startLat;
        double currentLng = startLng;

        for (final wp in candidate) {
          totalDist += _calculateHaversine(
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
