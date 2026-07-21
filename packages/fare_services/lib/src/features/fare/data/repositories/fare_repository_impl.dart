import 'package:core_models/core_models.dart';
import 'package:fare_services/src/features/fare/data/datasources/fare_remote_datasource.dart';
import 'package:fare_services/src/features/fare/domain/entities/fare_breakdown.dart';
import 'package:fare_services/src/features/fare/domain/entities/fare_estimate.dart';
import 'package:fare_services/src/features/fare/domain/entities/payment_method.dart';
import 'package:fare_services/src/features/fare/domain/repositories/fare_repository.dart';
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
        final double base = (res['base_fare'] as num?)?.toDouble() ?? 20.0;
        final double dist = (res['distance_charge'] as num?)?.toDouble() ?? (distanceKm * 10.0);
        final double time = (res['time_charge'] as num?)?.toDouble() ?? (durationMinutes * 1.5);
        final double surge = (res['surge_charge'] as num?)?.toDouble() ?? 0.0;
        final num? rawTotalNum = (res['estimated_fare'] ?? res['total_fare']) as num?;
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
      return Right(computeClientEstimate(distanceKm: distanceKm, durationMinutes: durationMinutes));
    } catch (_) {
      // Graceful fallback to client display estimate
      return Right(computeClientEstimate(distanceKm: distanceKm, durationMinutes: durationMinutes));
    }
  }

  @override
  FareEstimate computeClientEstimate({
    required double distanceKm,
    required double durationMinutes,
  }) {
    const double baseFare = 20.0;
    final double distCharge = distanceKm * 10.0;
    final double timeCharge = durationMinutes * 1.5;
    final double subtotal = baseFare + distCharge + timeCharge;
    final double total = subtotal < 25.0 ? 25.0 : ((subtotal * 2.0).round() / 2.0);

    return FareEstimate(
      breakdown: FareBreakdown(
        baseFare: baseFare,
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
