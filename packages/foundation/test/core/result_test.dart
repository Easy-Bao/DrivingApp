import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('folds a successful value without exception-based control flow', () {
    const Result<int, DomainFailure> result = Ok<int, DomainFailure>(42);

    expect(
      result.fold((failure) => failure.message, (value) => 'value:$value'),
      'value:42',
    );
  });

  test('folds a typed domain failure without exposing transport details', () {
    const Result<int, DomainFailure> result = Err<int, DomainFailure>(
      NetworkFailure('location stream unavailable'),
    );

    expect(
      result.fold((failure) => failure.message, (value) => 'value:$value'),
      'location stream unavailable',
    );
  });

  test('exposes branch checks and a typed fallback', () {
    const Result<int, DomainFailure> success = Ok<int, DomainFailure>(42);
    const Result<int, DomainFailure> failure = Err<int, DomainFailure>(
      NetworkFailure(),
    );

    expect(success.isOk, isTrue);
    expect(success.isErr, isFalse);
    expect(success.getOrElse((_) => 0), 42);
    expect(failure.isOk, isFalse);
    expect(failure.isErr, isTrue);
    expect(failure.getOrElse((_) => 0), 0);
  });

  test(
    'maps success values and failures without changing the other branch',
    () {
      const Result<int, DomainFailure> success = Ok<int, DomainFailure>(42);
      const Result<int, DomainFailure> failure = Err<int, DomainFailure>(
        NetworkFailure(),
      );

      expect(
        success.map((value) => value.toString()),
        const Ok<String, DomainFailure>('42'),
      );
      expect(
        failure.map((value) => value.toString()),
        const Err<String, DomainFailure>(NetworkFailure()),
      );
      expect(
        success.mapError((error) => ServerFailure(error.message)),
        const Ok<int, ServerFailure>(42),
      );
      final mappedFailure = failure.mapError(
        (error) => ServerFailure(error.message),
      );

      expect(mappedFailure, isA<Err<int, ServerFailure>>());
      expect(
        mappedFailure.fold((error) => error.message, (_) => ''),
        failure.fold((error) => error.message, (_) => ''),
      );
    },
  );
}
