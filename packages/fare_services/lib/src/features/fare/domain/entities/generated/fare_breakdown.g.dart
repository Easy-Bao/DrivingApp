// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../fare_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FareBreakdown _$FareBreakdownFromJson(Map<String, dynamic> json) =>
    _FareBreakdown(
      baseFare: (json['baseFare'] as num).toDouble(),
      distanceCharge: (json['distanceCharge'] as num).toDouble(),
      timeCharge: (json['timeCharge'] as num).toDouble(),
      surgeCharge: (json['surgeCharge'] as num).toDouble(),
      totalFare: (json['totalFare'] as num).toDouble(),
    );

Map<String, dynamic> _$FareBreakdownToJson(_FareBreakdown instance) =>
    <String, dynamic>{
      'baseFare': instance.baseFare,
      'distanceCharge': instance.distanceCharge,
      'timeCharge': instance.timeCharge,
      'surgeCharge': instance.surgeCharge,
      'totalFare': instance.totalFare,
    };
