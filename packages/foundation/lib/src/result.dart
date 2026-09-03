import 'package:foundation/src/errors/failures.dart';

typedef DomainFailure = Failure;

/// A closed success/failure value for data-layer work that must not leak
/// transport exceptions into presentation code.
sealed class Result<T, F extends DomainFailure> {
  const Result();

  R fold<R>(R Function(F failure) onErr, R Function(T value) onOk) {
    return switch (this) {
      Ok<T, F>(value: final value) => onOk(value),
      Err<T, F>(failure: final failure) => onErr(failure),
    };
  }
}

final class Ok<T, F extends DomainFailure> extends Result<T, F> {
  const Ok(this.value);

  final T value;
}

final class Err<T, F extends DomainFailure> extends Result<T, F> {
  const Err(this.failure);

  final F failure;
}
