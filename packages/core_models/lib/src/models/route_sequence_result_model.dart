import 'package:freezed_annotation/freezed_annotation.dart';
import 'waypoint_model.dart';

part 'generated/route_sequence_result_model.freezed.dart';
part 'generated/route_sequence_result_model.g.dart';

@freezed
abstract class RouteSequenceResult with _$RouteSequenceResult {
  const factory RouteSequenceResult({
    required List<Waypoint> optimalSequence,
    required double totalDistanceKm,
  }) = _RouteSequenceResult;

  factory RouteSequenceResult.fromJson(Map<String, dynamic> json) =>
      _$RouteSequenceResultFromJson(json);
}
