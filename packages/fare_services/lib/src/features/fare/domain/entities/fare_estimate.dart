import 'package:fare_services/src/features/fare/domain/entities/fare_breakdown.dart';
import 'package:fare_services/src/features/fare/domain/entities/payment_method.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/fare_estimate.freezed.dart';
part 'generated/fare_estimate.g.dart';

@freezed
abstract class FareEstimate with _$FareEstimate {
  const factory FareEstimate({
    required FareBreakdown breakdown,
    @Default(PaymentMethod.cashOnHand) PaymentMethod paymentMethod,
    @Default('PHP') String currency,
    @Default(false) bool isEstimateFallback,
  }) = _FareEstimate;

  factory FareEstimate.fromJson(Map<String, dynamic> json) =>
      _$FareEstimateFromJson(json);
}
