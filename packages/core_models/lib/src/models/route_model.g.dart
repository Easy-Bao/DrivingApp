// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteModel _$RouteModelFromJson(Map<String, dynamic> json) => _RouteModel(
  polylinePoints: (json['polylinePoints'] as List<dynamic>)
      .map(
        (e) => (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      )
      .toList(),
  distanceKm: (json['distanceKm'] as num).toDouble(),
  durationSeconds: (json['durationSeconds'] as num).toInt(),
  summary: json['summary'] as String? ?? '',
);

Map<String, dynamic> _$RouteModelToJson(_RouteModel instance) =>
    <String, dynamic>{
      'polylinePoints': instance.polylinePoints,
      'distanceKm': instance.distanceKm,
      'durationSeconds': instance.durationSeconds,
      'summary': instance.summary,
    };
