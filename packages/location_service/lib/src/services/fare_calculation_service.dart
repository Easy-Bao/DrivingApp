import 'package:core_models/core_models.dart';

/// Configuration parameters for fare calculations.
class FareConfig {
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double surgeMultiplier;
  final double minimumFare;

  const FareConfig({
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.surgeMultiplier,
    required this.minimumFare,
  });
}

/// Service to compute ride fares based on travel metrics and configs.
class FareCalculationService {
  /// Computes itemized fare breakdown and rounds the final sum to the nearest ₱0.50.
  static FareResult computeFare({
    required double distanceKm,
    required double durationMinutes,
    required FareConfig config,
  }) {
    final double distanceCharge = distanceKm * config.perKmRate;
    final double timeCharge = durationMinutes * config.perMinuteRate;
    final double subtotal = config.baseFare + distanceCharge + timeCharge;

    final double surgeCharge = config.surgeMultiplier > 1.0
        ? subtotal * (config.surgeMultiplier - 1.0)
        : 0.0;

    final double rawTotal = subtotal + surgeCharge;
    final double enforcedMin = rawTotal < config.minimumFare
        ? config.minimumFare
        : rawTotal;

    // Round to nearest ₱0.50
    final double totalFare = (enforcedMin * 2.0).round() / 2.0;

    return FareResult(
      baseFare: config.baseFare,
      distanceCharge: distanceCharge,
      timeCharge: timeCharge,
      surgeCharge: surgeCharge,
      totalFare: totalFare,
    );
  }

  /// Computes the fare with default BaoBao pricing configs.
  static FareResult computeFareDefault({
    required double distanceKm,
    required double durationMinutes,
  }) {
    return computeFare(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      config: const FareConfig(
        baseFare: 20.0,
        perKmRate: 10.0,
        perMinuteRate: 1.5,
        surgeMultiplier: 1.0,
        minimumFare: 25.0,
      ),
    );
  }
}
