import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('classifies socket failures without retaining socket text', () {
    final diagnostic = NetworkErrorDiagnostic.fromError(
      const SocketException(
        'Connection refused',
        osError: OSError('Connection refused', 111),
      ),
    );

    expect(diagnostic.category, NetworkErrorCategory.connectionRefused);
    expect(diagnostic.label, 'connection_refused');
  });

  test('classifies transport, cancellation, TLS, and parsing failures', () {
    final requestOptions = RequestOptions(path: '/health');
    expect(
      NetworkErrorDiagnostic.fromError(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        ),
      ).category,
      NetworkErrorCategory.connectionTimeout,
    );
    expect(
      NetworkErrorDiagnostic.fromError(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.cancel,
        ),
      ).category,
      NetworkErrorCategory.requestCancelled,
    );
    expect(
      NetworkErrorDiagnostic.fromError(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badCertificate,
        ),
      ).category,
      NetworkErrorCategory.tlsFailure,
    );
    expect(
      NetworkErrorDiagnostic.fromError(const FormatException('invalid JSON'))
          .category,
      NetworkErrorCategory.invalidServerResponse,
    );
  });

  test('classifies HTTP status categories and keeps their status code', () {
    final requestOptions = RequestOptions(path: '/health');
    final diagnostic = NetworkErrorDiagnostic.fromError(
      DioException(
        requestOptions: requestOptions,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 503,
        ),
      ),
    );

    expect(diagnostic.category, NetworkErrorCategory.serverError);
    expect(diagnostic.statusCode, 503);
    expect(diagnostic.label, 'http_server_error(503)');
  });
}
