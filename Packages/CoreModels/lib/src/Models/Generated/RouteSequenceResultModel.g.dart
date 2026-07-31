// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../RouteSequenceResultModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteSequenceResult _$RouteSequenceResultFromJson(Map<String, dynamic> json) =>
    RouteSequenceResult(
      optimalSequence: (json['optimalSequence'] as List<dynamic>)
          .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
    );

Map<String, dynamic> _$RouteSequenceResultToJson(
  RouteSequenceResult instance,
) => <String, dynamic>{
  'optimalSequence': instance.optimalSequence,
  'totalDistanceKm': instance.totalDistanceKm,
};
