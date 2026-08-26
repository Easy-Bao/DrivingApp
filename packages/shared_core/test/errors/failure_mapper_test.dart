import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('never carries server exception text into a domain failure', () {
    final failure = FailureMapper.fromException(
      ServerException(
        statusCode: 500,
        message: 'pq: relation passenger_profiles does not exist',
      ),
      serverMessage: 'Profile service is temporarily unavailable.',
    );

    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Profile service is temporarily unavailable.');
    expect(failure.message, isNot(contains('pq')));
    expect(failure.message, isNot(contains('500')));
  });

  test('maps the standard transport categories to safe failures', () {
    expect(
      FailureMapper.fromException(const SocketException('connection refused')),
      isA<NetworkFailure>(),
    );
    expect(
      FailureMapper.fromException(TimeoutException('internal timeout')),
      isA<ServerFailure>(),
    );
    expect(
      FailureMapper.fromException(
        _dioExceptionWithStatus(401, 'token invalid'),
      ),
      isA<AuthFailure>(),
    );
    expect(
      FailureMapper.fromException(
        _dioExceptionWithStatus(422, 'internal field key'),
      ),
      isA<ValidationFailure>(),
    );
  });

  test('keeps domain workflow failures typed', () {
    expect(
      FailureMapper.fromException(const NoDriversAvailableFailure()),
      isA<NoDriversAvailableFailure>(),
    );
    expect(
      FailureMapper.fromException(const PaymentDeclinedFailure()),
      isA<PaymentDeclinedFailure>(),
    );
  });
}

DioException _dioExceptionWithStatus(int statusCode, String message) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: message,
    ),
  );
}
