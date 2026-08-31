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
      'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
    );
    expect(message, isNot(contains('database')));
  });

  test('maps infrastructure failures to safe user-facing messages', () {
    expect(
      ErrorHandler.getErrorMessage(
        const CacheFailure('sqlite table passenger_saved_places is missing'),
      ),
      'Saved information is unavailable right now. Please try again.',
    );
    expect(
      ErrorHandler.getErrorMessage(
        const NetworkFailure('SocketException: connection refused'),
      ),
      'You are currently offline. Please check your Wi-Fi or mobile data.',
    );
    expect(
      ErrorHandler.getErrorMessage(
        const ValidationFailure('unexpected field passenger_internal_id'),
      ),
      'Please verify your input and correct the highlighted fields.',
    );
  });

  test('preserves the resolved-chat state message', () {
    expect(
      ErrorHandler.getErrorMessage(const ChatRoomLockedFailure()),
      'This chat has already been resolved.',
    );
  });

  test('maps HTTP statuses to the official safe message dictionary', () {
    final expectedMessages = <int, String>{
      401: 'Your session has expired. Please sign in again to continue.',
      403: 'You do not have permission to view or edit this resource.',
      400: 'Please verify your input and correct the highlighted fields.',
      422: 'Please verify your input and correct the highlighted fields.',
      429:
          'You are making requests too quickly. Please wait a moment before trying again.',
      503:
          'We are currently improving our services. We will be back online shortly.',
      504:
          'The server took too long to respond. Please check your connection and retry.',
      500:
          'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
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

    expect(failure.title, 'Under Maintenance');
    expect(failure.userMessage, contains('improving our services'));
    expect(failure.actionText, 'Refresh');
    expect(failure.type, ErrorType.server);
    expect(failure.technicalLog, same(technicalError));
    expect(failure.userMessage, isNot(contains('database')));
  });

  test('maps connection and timeout failures safely', () {
    expect(
      ErrorHandler.getErrorMessage(const SocketException('connection refused')),
      'You are currently offline. Please check your Wi-Fi or mobile data.',
    );
    expect(
      ErrorHandler.getErrorMessage(TimeoutException('internal timeout')),
      'The server took too long to respond. Please check your connection and retry.',
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
