import 'package:fare_services/src/features/fare/domain/entities/service_pricing_config.dart';

class FareCalculatorHelper {
  FareCalculatorHelper._();

  /// Centralized default pricing configurations for each service type.
  /// Backend serves as the single source of truth; these act as structured defaults.
  static const Map<String, ServicePricingConfig> defaultConfigs = {
    'Solo Ride': ServicePricingConfig(
      serviceName: 'Solo Ride',
      baseFare: 20.0,
      perKmRate: 10.0,
      perMinuteRate: 1.5,
      minimumFare: 25.0,
    ),
    'Share-Bao': ServicePricingConfig(
      serviceName: 'Share-Bao',
      baseFare: 15.0,
      perKmRate: 7.0,
      perMinuteRate: 1.0,
      minimumFare: 20.0,
    ),
    'Bao Premium': ServicePricingConfig(
      serviceName: 'Bao Premium',
      baseFare: 35.0,
      perKmRate: 15.0,
      perMinuteRate: 2.0,
      minimumFare: 40.0,
    ),
  };

  static final Map<String, ServicePricingConfig> _activeConfigs =
      Map.from(defaultConfigs);

  static Map<String, ServicePricingConfig> get activeConfigs => _activeConfigs;

  /// Updates active pricing rules dynamically fetched from backend API.
  static void updateConfigsFromBackend(List<ServicePricingConfig> configs) {
    for (final config in configs) {
      _activeConfigs[config.serviceName] = config;
    }
  }

  /// Computes estimated fare for a given service type using centralized rules.
  static double estimateFare({
    required String serviceType,
    required double distanceKm,
    double durationMinutes = 0.0,
  }) {
    final config = _activeConfigs[serviceType] ??
        defaultConfigs[serviceType] ??
        ServicePricingConfig(
          serviceName: serviceType,
          baseFare: 20.0,
          perKmRate: 10.0,
        );
    return config.calculateFare(distanceKm, durationMinutes: durationMinutes);
  }

  /// Returns estimated fares for all available service types.
  static Map<String, double> estimateAllFares({
    required double distanceKm,
    double durationMinutes = 0.0,
  }) {
    return {
      for (final entry in defaultConfigs.entries)
        entry.key: entry.value.calculateFare(
          distanceKm,
          durationMinutes: durationMinutes,
        ),
    };
  }
}
