import 'package:foundation/src/errors/failures.dart';

typedef DomainFailure = Failure;

/// A closed success/failure value for data-layer work that must not leak
/// transport exceptions into presentation code.
sealed class Result<T, F extends DomainFailure> {
  const Result();

  bool get isOk => this is Ok<T, F>;

  bool get isErr => this is Err<T, F>;

  R fold<R>(R Function(F failure) onErr, R Function(T value) onOk) {
    return switch (this) {
      Ok<T, F>(value: final value) => onOk(value),
      Err<T, F>(failure: final failure) => onErr(failure),
    };
  }

  T getOrElse(T Function(F failure) onErr) {
    return switch (this) {
      Ok<T, F>(value: final value) => value,
      Err<T, F>(failure: final failure) => onErr(failure),
    };
  }

  Result<U, F> map<U>(U Function(T value) transform) {
    return switch (this) {
      Ok<T, F>(value: final value) => Ok<U, F>(transform(value)),
      Err<T, F>(failure: final failure) => Err<U, F>(failure),
    };
  }

  Result<T, G> mapError<G extends DomainFailure>(
    G Function(F failure) transform,
  ) {
    return switch (this) {
      Ok<T, F>(value: final value) => Ok<T, G>(value),
      Err<T, F>(failure: final failure) => Err<T, G>(transform(failure)),
    };
  }
}

final class Ok<T, F extends DomainFailure> extends Result<T, F> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) {
    return other is Ok<T, F> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

final class Err<T, F extends DomainFailure> extends Result<T, F> {
  const Err(this.failure);

  final F failure;

  @override
  bool operator ==(Object other) {
    return other is Err<T, F> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;
}
