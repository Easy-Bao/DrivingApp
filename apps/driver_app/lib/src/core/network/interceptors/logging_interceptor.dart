import 'dart:developer' as dev;
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    dev.log(
      'REQUEST[${options.method}] => PATH: ${options.path}',
      name: 'HTTP',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dev.log(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      name: 'HTTP',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      name: 'HTTP',
      error: err,
    );
    handler.next(err);
  }
}
