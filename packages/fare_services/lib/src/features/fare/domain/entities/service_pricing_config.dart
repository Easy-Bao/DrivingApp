import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/service_pricing_config.freezed.dart';
part 'generated/service_pricing_config.g.dart';

@freezed
abstract class ServicePricingConfig with _$ServicePricingConfig {
  const ServicePricingConfig._();

  const factory ServicePricingConfig({
    required String serviceName,
    required double baseFare,
    required double perKmRate,
    @Default(1.5) double perMinuteRate,
    @Default(25.0) double minimumFare,
  }) = _ServicePricingConfig;

  factory ServicePricingConfig.fromJson(Map<String, dynamic> json) =>
      _$ServicePricingConfigFromJson(json);

  /// Calculates total estimated fare based on distance in kilometers and duration in minutes.
  double calculateFare(double distanceKm, {double durationMinutes = 0.0}) {
    final rawSubtotal =
        baseFare + (distanceKm * perKmRate) + (durationMinutes * perMinuteRate);
    final total = rawSubtotal < minimumFare ? minimumFare : rawSubtotal;
    return (total * 2.0).round() / 2.0;
  }
}
