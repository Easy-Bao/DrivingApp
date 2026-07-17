import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/fare_result.freezed.dart';
part 'generated/fare_result.g.dart';

@freezed
abstract class FareResult with _$FareResult {
  const factory FareResult({
    required double baseFare,
    required double distanceCharge,
    required double timeCharge,
    required double surgeCharge,
    required double totalFare,
  }) = _FareResult;

  factory FareResult.fromJson(Map<String, dynamic> json) =>
      _$FareResultFromJson(json);
}
