import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/fare_breakdown.freezed.dart';
part 'generated/fare_breakdown.g.dart';

@freezed
abstract class FareBreakdown with _$FareBreakdown {
  const factory FareBreakdown({
    required double baseFare,
    required double distanceCharge,
    required double timeCharge,
    required double surgeCharge,
    required double totalFare,
  }) = _FareBreakdown;

  factory FareBreakdown.fromJson(Map<String, dynamic> json) =>
      _$FareBreakdownFromJson(json);
}
