import 'dart:io';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;

  RetryInterceptor(this.dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final isRetryableMethod = switch (requestOptions.method.toUpperCase()) {
      'GET' || 'HEAD' || 'OPTIONS' => true,
      _ => false,
    };
    final isNetworkError =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.error is SocketException;
    final retryAttempt = requestOptions.extra['retryAttempt'] as int? ?? 0;

    if (isRetryableMethod && isNetworkError && retryAttempt < 2) {
      requestOptions.extra['retryAttempt'] = retryAttempt + 1;
      await Future<void>.delayed(
        Duration(milliseconds: 250 * (retryAttempt + 1)),
      );
      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (_) {}
    }
    super.onError(err, handler);
  }
}
