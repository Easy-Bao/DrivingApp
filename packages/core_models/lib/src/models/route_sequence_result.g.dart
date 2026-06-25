// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_sequence_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteSequenceResult _$RouteSequenceResultFromJson(Map<String, dynamic> json) =>
    _RouteSequenceResult(
      optimalSequence: (json['optimalSequence'] as List<dynamic>)
          .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
    );

Map<String, dynamic> _$RouteSequenceResultToJson(
  _RouteSequenceResult instance,
) => <String, dynamic>{
  'optimalSequence': instance.optimalSequence,
  'totalDistanceKm': instance.totalDistanceKm,
};
