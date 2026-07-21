// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../fare_estimate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FareEstimate _$FareEstimateFromJson(Map<String, dynamic> json) =>
    _FareEstimate(
      breakdown:
          FareBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']) ??
              PaymentMethod.cashOnHand,
      currency: json['currency'] as String? ?? 'PHP',
      isEstimateFallback: json['isEstimateFallback'] as bool? ?? false,
    );

Map<String, dynamic> _$FareEstimateToJson(_FareEstimate instance) =>
    <String, dynamic>{
      'breakdown': instance.breakdown,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'currency': instance.currency,
      'isEstimateFallback': instance.isEstimateFallback,
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.cashOnHand: 'cashOnHand',
};
