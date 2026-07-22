import 'package:fare_services/src/features/fare/domain/entities/service_pricing_config.dart';

class FareCalculatorHelper {
  FareCalculatorHelper._();

  static final Map<String, ServicePricingConfig> _activePricingRules = {
    'Solo Ride': const ServicePricingConfig(
      serviceName: 'Solo Ride',
      baseFare: 20.0,
      perKmRate: 10.0,
      perMinuteRate: 1.5,
      minimumFare: 25.0,
    ),
    'Share-Bao': const ServicePricingConfig(
      serviceName: 'Share-Bao',
      baseFare: 15.0,
      perKmRate: 7.0,
      perMinuteRate: 1.0,
      minimumFare: 20.0,
    ),
    'Bao Premium': const ServicePricingConfig(
      serviceName: 'Bao Premium',
      baseFare: 35.0,
      perKmRate: 15.0,
      perMinuteRate: 2.0,
      minimumFare: 40.0,
    ),
  };

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
    final pricingConfig = _activePricingRules[serviceType] ??
        ServicePricingConfig(
          serviceName: serviceType,
          baseFare: 20.0,
          perKmRate: 10.0,
        );
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
