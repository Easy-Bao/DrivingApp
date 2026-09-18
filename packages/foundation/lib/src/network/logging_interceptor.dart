import 'dart:developer' as dev;

import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    dev.log(HttpLogFormatter.request(options), name: 'HTTP');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dev.log(HttpLogFormatter.response(response), name: 'HTTP');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log(HttpLogFormatter.error(err), name: 'HTTP');
    handler.next(err);
  }
}

/// Formats diagnostics without including headers, query parameters, or body
/// data that could contain credentials or other request secrets.
final class HttpLogFormatter {
  static String request(RequestOptions options) {
    return 'REQUEST[${options.method}] => PATH: ${_path(options.uri)}';
  }

  static String response(Response response) {
    return 'RESPONSE[${response.statusCode}] => PATH: '
        '${_path(response.requestOptions.uri)}';
  }

  static String error(DioException error) {
    return 'ERROR[${error.response?.statusCode ?? 'network'}] '
        '${error.type.name} => PATH: ${_path(error.requestOptions.uri)}';
  }

  static String _path(Uri uri) => uri.path.isEmpty ? '/' : uri.path;
}
