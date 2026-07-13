import 'package:freezed_annotation/freezed_annotation.dart';
import 'waypoint.dart';

part 'generated/route_sequence_result.freezed.dart';
part 'generated/route_sequence_result.g.dart';

/// RouteSequenceResult represents calculated metrics of an optimized path traversal.
@freezed
abstract class RouteSequenceResult with _$RouteSequenceResult {
  const factory RouteSequenceResult({
    required List<Waypoint> optimalSequence,
    required double totalDistanceKm,
  }) = _RouteSequenceResult;

  factory RouteSequenceResult.fromJson(Map<String, dynamic> json) =>
      _$RouteSequenceResultFromJson(json);
}
