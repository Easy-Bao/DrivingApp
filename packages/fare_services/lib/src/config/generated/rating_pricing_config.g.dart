// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../rating_pricing_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RatingPricingConfig _$RatingPricingConfigFromJson(Map<String, dynamic> json) =>
    _RatingPricingConfig(
      minimumRatingThreshold:
          (json['minimumRatingThreshold'] as num?)?.toDouble() ?? 4.5,
      highRatingBonusMultiplier:
          (json['highRatingBonusMultiplier'] as num?)?.toDouble() ?? 1.05,
      lowRatingSurgePenaltyMultiplier:
          (json['lowRatingSurgePenaltyMultiplier'] as num?)?.toDouble() ?? 1.0,
      baseSurgeCap: (json['baseSurgeCap'] as num?)?.toDouble() ?? 2.5,
    );

Map<String, dynamic> _$RatingPricingConfigToJson(
        _RatingPricingConfig instance) =>
    <String, dynamic>{
      'minimumRatingThreshold': instance.minimumRatingThreshold,
      'highRatingBonusMultiplier': instance.highRatingBonusMultiplier,
      'lowRatingSurgePenaltyMultiplier':
          instance.lowRatingSurgePenaltyMultiplier,
      'baseSurgeCap': instance.baseSurgeCap,
    };
