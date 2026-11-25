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

    expect(message, 'The server could not complete your request. Try again.');
    expect(message, isNot(contains('database')));
  });

  test(
    'surfaces the missing configuration key instead of a generic message',
    () {
      final failure = ErrorHandler.getAppFailure(
        const ConfigurationException('API_BASE_URL is required.'),
      );

      expect(failure.title, 'App configuration error');
      expect(failure.userMessage, 'API_BASE_URL is required.');
      expect(failure.type, ErrorType.configuration);
    },
  );

  test('maps response parsing errors to an explicit format message', () {
    final failure = ErrorHandler.getAppFailure(
      const DataParsingException(message: 'missing field driver_id'),
    );

    expect(failure.title, 'Invalid server response');
    expect(
      failure.userMessage,
      'Received an unexpected response format. Try again.',
    );
    expect(failure.userMessage, isNot(contains('driver_id')));
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
      404: 'The requested item was not found on the server.',
      408: 'The request took too long. Try again.',
      409: 'This information changed on the server. Refresh and try again.',
      429: 'Too many requests. Wait a moment and try again.',
      502: 'The server received an invalid response upstream. Try again later.',
      503: 'The service is unavailable. Try again later.',
      504: 'The request took too long. Try again.',
      500: 'The server encountered an error. Try again later.',
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
    final technicalError = const ServerException(
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

  test(
    'maps connection, TLS, cancellation, and timeout failures specifically',
    () {
      expect(
        ErrorHandler.getErrorMessage(
          const SocketException(
            'Connection refused',
            osError: OSError('Connection refused', 111),
          ),
        ),
        'Cannot reach the server. Check that the server is running and try again.',
      );
      expect(
        ErrorHandler.getErrorMessage(
          const NetworkCircuitOpenException(
            category: NetworkErrorCategory.connectionRefused,
          ),
        ),
        'Cannot reach the server. Check that the server is running and try again.',
      );
      expect(
        ErrorHandler.getErrorMessage(
          const SocketException(
            'Network is unreachable',
            osError: OSError('Network is unreachable', 101),
          ),
        ),
        "Couldn't connect. Check your internet connection and try again.",
      );
      expect(
        ErrorHandler.getErrorMessage(const HandshakeException('tls failed')),
        'Could not verify a secure server connection. Check your network or device clock and try again.',
      );
      expect(
        ErrorHandler.getErrorMessage(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.cancel,
          ),
        ),
        'The request was cancelled before completing. Try again.',
      );
      expect(
        ErrorHandler.getErrorMessage(TimeoutException('internal timeout')),
        'The request took too long. Try again.',
      );
      expect(
        ErrorHandler.getErrorMessage(
          const SocketException(
            'Connection refused',
            osError: OSError('Connection refused', 61),
          ),
        ),
        'Cannot reach the server. Check that the server is running and try again.',
      );
    },
  );

  test('preserves BusinessRuleFailure messages and Failure equality', () {
    expect(
      ErrorHandler.getErrorMessage(
        const BusinessRuleFailure('Go offline before changing vehicle.'),
      ),
      'Go offline before changing vehicle.',
    );
    expect(
      const ServerFailure('A', 500),
      equals(const ServerFailure('A', 500)),
    );
    expect(
      const ServerFailure('A', 500),
      isNot(equals(const ServerFailure('A', 503))),
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
