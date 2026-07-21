// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../service_pricing_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServicePricingConfig _$ServicePricingConfigFromJson(
        Map<String, dynamic> json) =>
    _ServicePricingConfig(
      serviceName: json['serviceName'] as String,
      baseFare: (json['baseFare'] as num).toDouble(),
      perKmRate: (json['perKmRate'] as num).toDouble(),
      perMinuteRate: (json['perMinuteRate'] as num?)?.toDouble() ?? 1.5,
      minimumFare: (json['minimumFare'] as num?)?.toDouble() ?? 25.0,
    );

Map<String, dynamic> _$ServicePricingConfigToJson(
        _ServicePricingConfig instance) =>
    <String, dynamic>{
      'serviceName': instance.serviceName,
      'baseFare': instance.baseFare,
      'perKmRate': instance.perKmRate,
      'perMinuteRate': instance.perMinuteRate,
      'minimumFare': instance.minimumFare,
    };
