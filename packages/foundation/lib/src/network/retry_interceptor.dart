import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

enum RequestRetryPolicy { transientRead }

const requestRetryPolicyExtraKey = 'requestRetryPolicy';

typedef RetryDelay = Duration Function(int retryAttempt);

class RetryInterceptor(this.dio, {RetryDelay? retryDelay}) extends Interceptor {
  final Dio dio;
  final RetryDelay _retryDelay;

  this : _retryDelay = retryDelay ?? _defaultRetryDelay;

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
    final retryPolicy =
        requestOptions.extra[requestRetryPolicyExtraKey] as RequestRetryPolicy?;

    if (retryPolicy == RequestRetryPolicy.transientRead &&
        isRetryableMethod &&
        isNetworkError &&
        retryAttempt < 2) {
      requestOptions.extra['retryAttempt'] = retryAttempt + 1;
      await Future<void>.delayed(_retryDelay(retryAttempt + 1));
      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (_) {}
    }
    super.onError(err, handler);
  }

  static Duration _defaultRetryDelay(int retryAttempt) {
    final boundedAttempt = retryAttempt.clamp(1, 4);
    final baseMilliseconds = 250 * (1 << (boundedAttempt - 1));
    final jitterMilliseconds = Random().nextInt(126);
    return Duration(milliseconds: baseMilliseconds + jitterMilliseconds);
  }
}
