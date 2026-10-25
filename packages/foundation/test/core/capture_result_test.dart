import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('retains a successful value and invokes the operation once', () async {
    final pending = Completer<Result<Object, Failure>>();
    final value = Object();
    var calls = 0;
    final future = captureResult(() {
      calls++;
      return pending.future;
    }, message: 'Unavailable');
    expect(calls, 1);
    pending.complete(Ok(value));
    final result = await future;
    expect(result.getOrElse((_) => fail('expected success')), same(value));
    expect(calls, 1);
  });

  test('retains returned failures without remapping their messages', () async {
    const failure = ValidationFailure('Choose a valid destination.');
    final result = await captureResult<int>(
      () async => const Err(failure),
      message: 'Unavailable',
    );
    result.fold(
      (value) => expect(value, same(failure)),
      (_) => fail('expected failure'),
    );
  });

  test('captures synchronous exceptions with the operation message', () async {
    final result = await captureResult<int>(
      () => throw StateError('internal detail'),
      message: 'Trip unavailable.',
    );
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Trip unavailable.');
    }, (_) => fail('expected failure'));
  });

  test('captures asynchronous exceptions with the operation message', () async {
    final result = await captureResult<int>(
      () async => throw const FormatException('invalid payload'),
      message: 'Fare unavailable.',
    );
    result.fold(
      (failure) => expect(failure.message, 'Fare unavailable.'),
      (_) => fail('expected failure'),
    );
  });

  test('preserves network classification for transport exceptions', () async {
    final result = await captureResult<int>(
      () async => throw const SocketException('offline'),
      message: 'Trip unavailable.',
    );
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected failure'),
    );
  });

  test('supports commands without a response body', () async {
    final result = await captureResult<void>(
      () async => const Ok(null),
      message: 'Command unavailable.',
    );
    expect(result.isOk, isTrue);
  });
}
