import 'package:fare_services/src/features/fare/domain/entities/service_pricing_config.dart';

class FareCalculatorHelper {
  FareCalculatorHelper._();

  static final Map<String, ServicePricingConfig> _activePricingRules = {};

  static Map<String, ServicePricingConfig> get activeConfigs => _activePricingRules;

  /// Synchronizes active service pricing rules received from the backend authority service.
  static void synchronizeServicePricingRules(
    List<ServicePricingConfig> pricingConfigurations,
  ) {
    for (final pricingConfig in pricingConfigurations) {
      _activePricingRules[pricingConfig.serviceName] = pricingConfig;
    }
  }

  /// Calculates estimated fare for a designated service type using active pricing rules.
  static double estimateFare({
    required String serviceType,
    required double distanceKm,
    double durationMinutes = 0.0,
  }) {
    final pricingConfig = _activePricingRules[serviceType];
    if (pricingConfig == null) {
      return 0.0;
    }
    return pricingConfig.calculateFare(
      distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  /// Calculates estimated fares across all synchronized service types.
  static Map<String, double> estimateAllFares({
    required double distanceKm,
    double durationMinutes = 0.0,
  }) {
    return {
      for (final entry in _activePricingRules.entries)
        entry.key: entry.value.calculateFare(
          distanceKm,
          durationMinutes: durationMinutes,
        ),
    };
  }
}
