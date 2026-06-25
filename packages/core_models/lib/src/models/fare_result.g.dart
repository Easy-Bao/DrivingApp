// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fare_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FareResult _$FareResultFromJson(Map<String, dynamic> json) => _FareResult(
  baseFare: (json['baseFare'] as num).toDouble(),
  distanceCharge: (json['distanceCharge'] as num).toDouble(),
  timeCharge: (json['timeCharge'] as num).toDouble(),
  surgeCharge: (json['surgeCharge'] as num).toDouble(),
  totalFare: (json['totalFare'] as num).toDouble(),
);

Map<String, dynamic> _$FareResultToJson(_FareResult instance) =>
    <String, dynamic>{
      'baseFare': instance.baseFare,
      'distanceCharge': instance.distanceCharge,
      'timeCharge': instance.timeCharge,
      'surgeCharge': instance.surgeCharge,
      'totalFare': instance.totalFare,
    };
