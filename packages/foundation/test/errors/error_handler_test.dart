import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('does not expose server failure details to the user', () {
    final message = ErrorHandler.getErrorMessage(
      const ServerFailure('database password leaked by the server'),
    );

    expect(
      message,
      'Something went wrong. Try again.',
    );
    expect(message, isNot(contains('database')));
  });

  test('maps infrastructure failures to safe user-facing messages', () {
    expect(
      ErrorHandler.getErrorMessage(
        const CacheFailure('sqlite table passenger_saved_places is missing'),
      ),
      'Saved information is unavailable. Try again.',
    );
    expect(
      ErrorHandler.getErrorMessage(
        const NetworkFailure('SocketException: connection refused'),
      ),
      "Couldn't connect. Check your internet connection and try again.",
    );
    expect(
      ErrorHandler.getErrorMessage(
        const ValidationFailure('unexpected field passenger_internal_id'),
      ),
      'Check the highlighted fields.',
    );
  });

  test('maps HTTP statuses to the official safe message dictionary', () {
    final expectedMessages = <int, String>{
      401: 'Your session has expired. Sign in again.',
      403: "You don't have permission to do that.",
      400: 'Check the highlighted fields.',
      422: 'Check the highlighted fields.',
      429: 'Too many requests. Wait a moment and try again.',
      503: 'The service is unavailable. Try again later.',
      504: 'The request took too long. Try again.',
      500: 'Something went wrong. Try again.',
    };

    for (final entry in expectedMessages.entries) {
      final message = ErrorHandler.getErrorMessage(
        _dioExceptionWithStatus(entry.key, 'pq: relation does not exist'),
      );

      expect(message, entry.value);
      expect(message, isNot(contains('pq')));
      expect(message, isNot(contains(entry.key.toString())));
    }
  });

  test('keeps title, CTA, type, and technical details separate', () {
    final technicalError = ServerException(
      statusCode: 503,
      message: 'database relation passenger_profiles is missing',
    );

    final failure = ErrorHandler.getAppFailure(technicalError);

    expect(failure.title, 'Service unavailable');
    expect(failure.userMessage, contains('service is unavailable'));
    expect(failure.actionText, 'Retry');
    expect(failure.type, ErrorType.server);
    expect(failure.technicalLog, same(technicalError));
    expect(failure.userMessage, isNot(contains('database')));
  });

  test('maps connection and timeout failures safely', () {
    expect(
      ErrorHandler.getErrorMessage(const SocketException('connection refused')),
      "Couldn't connect. Check your internet connection and try again.",
    );
    expect(
      ErrorHandler.getErrorMessage(TimeoutException('internal timeout')),
      'The request took too long. Try again.',
    );
  });
}

DioException _dioExceptionWithStatus(int statusCode, String responseBody) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: responseBody,
    ),
  );
}
