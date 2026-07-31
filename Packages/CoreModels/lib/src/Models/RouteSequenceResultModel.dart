import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'WaypointModel.dart';

part 'Generated/RouteSequenceResultModel.g.dart';

@JsonSerializable()
class RouteSequenceResult extends Equatable {
  final List<Waypoint> optimalSequence;
  final double totalDistanceKm;

  const RouteSequenceResult({
    required this.optimalSequence,
    required this.totalDistanceKm,
  });

  factory RouteSequenceResult.fromJson(Map<String, dynamic> json) =>
      _$RouteSequenceResultFromJson(json);

  Map<String, dynamic> toJson() => _$RouteSequenceResultToJson(this);

  @override
  List<Object?> get props => [optimalSequence, totalDistanceKm];
}

