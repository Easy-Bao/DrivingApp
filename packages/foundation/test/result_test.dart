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
}
