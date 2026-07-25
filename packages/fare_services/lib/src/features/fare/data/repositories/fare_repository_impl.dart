import 'package:core_models/core_models.dart';
import 'package:fare_services/src/features/fare/data/datasources/fare_remote_datasource.dart';
import 'package:fare_services/src/features/fare/domain/entities/fare_breakdown.dart';
import 'package:fare_services/src/features/fare/domain/entities/fare_estimate.dart';
import 'package:fare_services/src/features/fare/domain/entities/payment_method.dart';
import 'package:fare_services/src/features/fare/domain/repositories/fare_repository.dart';
import 'package:fare_services/src/features/fare/presentation/fare_calculator_helper.dart';
import 'package:fpdart/fpdart.dart';

class FareRepositoryImpl implements FareRepository {
  final FareRemoteDataSource _remoteDataSource;

  FareRepositoryImpl({required FareRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, FareEstimate>> getFareQuote({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  }) async {
    try {
      final res = await _remoteDataSource.fetchFareQuote(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        rideType: rideType,
      );

      if (res.isNotEmpty) {
        final Map<String, dynamic> payload = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        Map<String, dynamic> targetMap = payload;
        if (payload['estimates'] is List && (payload['estimates'] as List).isNotEmpty) {
          final list = payload['estimates'] as List;
          final match = list.firstWhere(
            (item) => item is Map<String, dynamic> && (item['serviceType'] == rideType || item['service_type'] == rideType),
            orElse: () => list.first,
          );
          if (match is Map<String, dynamic>) {
            targetMap = match;
          }
        }

        final num? baseNum = (targetMap['baseFare'] ?? targetMap['base_fare']) as num?;
        final num? distNum = (targetMap['distanceCharge'] ?? targetMap['distance_charge']) as num?;
        final num? timeNum = (targetMap['timeCharge'] ?? targetMap['time_charge']) as num?;
        final num? surgeNum = (targetMap['surgeCharge'] ?? targetMap['surge_charge']) as num?;
        final num? rawTotalNum = (targetMap['totalFare'] ?? targetMap['total_fare'] ?? targetMap['estimated_fare']) as num?;

        final double base = baseNum?.toDouble() ?? 20.0;
        final double dist = distNum?.toDouble() ?? (distanceKm * 10.0);
        final double time = timeNum?.toDouble() ?? (durationMinutes * 1.5);
        final double surge = surgeNum?.toDouble() ?? 0.0;
        final double total = rawTotalNum?.toDouble() ?? (base + dist + time + surge);

        final breakdown = FareBreakdown(
          baseFare: base,
          distanceCharge: dist,
          timeCharge: time,
          surgeCharge: surge,
          totalFare: total,
        );

        return Right(
          FareEstimate(
            breakdown: breakdown,
            paymentMethod: PaymentMethod.cashOnHand,
            isEstimateFallback: false,
          ),
        );
      }
      return Right(calculateFallbackFareEstimate(distanceKm: distanceKm, durationMinutes: durationMinutes));
    } catch (_) {
      // Graceful fallback to active rules estimate
      return Right(calculateFallbackFareEstimate(distanceKm: distanceKm, durationMinutes: durationMinutes));
    }
  }

  @override
  FareEstimate calculateFallbackFareEstimate({
    required double distanceKm,
    required double durationMinutes,
  }) {
    final config = FareCalculatorHelper.activeConfigs['Solo Ride'] ??
        FareCalculatorHelper.activeConfigs.values.firstOrNull;

    if (config == null) {
      return const FareEstimate(
        breakdown: FareBreakdown(
          baseFare: 0.0,
          distanceCharge: 0.0,
          timeCharge: 0.0,
          surgeCharge: 0.0,
          totalFare: 0.0,
        ),
        paymentMethod: PaymentMethod.cashOnHand,
        isEstimateFallback: true,
      );
    }

    final double distCharge = distanceKm * config.perKmRate;
    final double timeCharge = durationMinutes * config.perMinuteRate;
    final double total = config.calculateFare(distanceKm, durationMinutes: durationMinutes);

    return FareEstimate(
      breakdown: FareBreakdown(
        baseFare: config.baseFare,
        distanceCharge: distCharge,
        timeCharge: timeCharge,
        surgeCharge: 0.0,
        totalFare: total,
      ),
      paymentMethod: PaymentMethod.cashOnHand,
      isEstimateFallback: true,
    );
  }
}
