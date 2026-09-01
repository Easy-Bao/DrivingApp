import 'package:passenger/src/features/booking/domain/entities/fare_estimate.dart';

final class const FareEstimateDto(this.value) {
  factory fromJson(Map<String, dynamic> json) {
    return FareEstimateDto(FareEstimate.fromJson(json));
  }

  final FareEstimate value;

  FareEstimate toDomain() => value;

  Map<String, dynamic> toJson() => value.toJson();
}
