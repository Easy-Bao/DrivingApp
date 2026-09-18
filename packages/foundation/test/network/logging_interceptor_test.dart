import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('request diagnostics exclude bearer tokens and query parameters', () {
    final options = RequestOptions(
      baseUrl: 'https://api.example.test',
      path: '/api/v1/profile',
      queryParameters: {'access_token': 'secret-query-token'},
      headers: {'Authorization': 'Bearer secret-header-token'},
    );

    final message = HttpLogFormatter.request(options);

    expect(message, 'REQUEST[GET] => PATH: /api/v1/profile');
    expect(message, isNot(contains('secret-header-token')));
    expect(message, isNot(contains('secret-query-token')));
  });

  test('response and error diagnostics keep only the request path', () {
    final options = RequestOptions(
      baseUrl: 'https://api.example.test',
      path: '/api/v1/profile',
      queryParameters: {'refresh_token': 'secret-refresh-token'},
      headers: {'Authorization': 'Bearer secret-header-token'},
    );
    final response = Response<Object?>(requestOptions: options, statusCode: 401);
    final error = DioException(
      requestOptions: options,
      response: response,
      type: DioExceptionType.badResponse,
    );

    expect(HttpLogFormatter.response(response), contains('/api/v1/profile'));
    expect(HttpLogFormatter.error(error), contains('/api/v1/profile'));
    expect(HttpLogFormatter.error(error), isNot(contains('secret')));
  });
}
