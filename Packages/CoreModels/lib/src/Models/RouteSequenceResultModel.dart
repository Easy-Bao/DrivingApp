import 'package:equatable/equatable.dart';
import 'WaypointModel.dart';

class RouteSequenceResult extends Equatable {
  final List<Waypoint> optimalSequence;
  final double totalDistanceKm;

  const RouteSequenceResult({
    required this.optimalSequence,
    required this.totalDistanceKm,
  });

  factory RouteSequenceResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['optimalSequence'] as List<dynamic>? ?? json['optimal_sequence'] as List<dynamic>? ?? [];
    final waypoints = rawList.map((item) => Waypoint.fromJson(item as Map<String, dynamic>)).toList();
    return RouteSequenceResult(
      optimalSequence: waypoints,
      totalDistanceKm: (json['totalDistanceKm'] as num? ?? json['total_distance_km'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optimalSequence': optimalSequence.map((w) => w.toJson()).toList(),
      'totalDistanceKm': totalDistanceKm,
    };
  }

  @override
  List<Object?> get props => [optimalSequence, totalDistanceKm];
}
