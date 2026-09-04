import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/booking/domain/entities/fare_estimate.dart';
import 'package:passenger/src/features/booking/domain/repositories/fare_repository.dart';

final class _FakeFareRepository implements FareRepository {
  _FakeFareRepository(this._result);

  final Either<Failure, FareEstimate> _result;

  @override
  Future<Either<Failure, FareEstimate>> estimateFare({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async => _result;
}

void main() {
  const estimate = FareEstimate(
    baseFare: 50,
    distanceCharge: 125.5,
    timeCharge: 30,
    surgeCharge: 10,
    totalFare: 215.5,
  );

  test(
    'converts the legacy fare contract into a strict success result',
    () async {
      final FareRepository repository = _FakeFareRepository(
        const Right(estimate),
      );

      final result = await repository.estimateFareResult(
        distanceKm: 3,
        durationMinutes: 12,
        originLatitude: 7.8,
        originLongitude: 123.4,
        destinationLatitude: 7.9,
        destinationLongitude: 123.5,
      );

      expect(result, isA<Ok<FareEstimate, DomainFailure>>());
      expect(result.fold((_) => null, (value) => value), estimate);
    },
  );

  test(
    'captures unexpected legacy repository exceptions as domain failures',
    () async {
      final FareRepository repository = _ThrowingFareRepository();

      final result = await repository.estimateFareResult(
        distanceKm: 3,
        durationMinutes: 12,
        originLatitude: 7.8,
        originLongitude: 123.4,
        destinationLatitude: 7.9,
        destinationLongitude: 123.5,
      );

      expect(result, isA<Err<FareEstimate, DomainFailure>>());
      expect(
        result.fold((failure) => failure.message, (_) => null),
        'Fare calculation is temporarily unavailable.',
      );
    },
  );
}

final class _ThrowingFareRepository implements FareRepository {
  @override
  Future<Either<Failure, FareEstimate>> estimateFare({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    throw StateError('transport failure');
  }
}
