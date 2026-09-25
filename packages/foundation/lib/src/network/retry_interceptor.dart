import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

enum RequestRetryPolicy { transientRead }

const requestRetryPolicyExtraKey = 'requestRetryPolicy';

typedef RetryDelay = Duration Function(int retryAttempt);

class RetryInterceptor(
  this.dio, {
  RetryDelay? retryDelay,
  bool retrySafeReadsByDefault = false,
}) extends Interceptor {
  final Dio dio;
  final bool _retrySafeReadsByDefault;
  final RetryDelay _retryDelay;

  this
    : _retrySafeReadsByDefault = retrySafeReadsByDefault,
      _retryDelay = retryDelay ?? _defaultRetryDelay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final retryPolicy =
        requestOptions.extra[requestRetryPolicyExtraKey] as RequestRetryPolicy?;
    final method = requestOptions.method.toUpperCase();
    final isSafeReadMethod = switch (method) {
      'GET' || 'HEAD' || 'OPTIONS' => true,
      _ => false,
    };
    final isRetryableMethod =
        isSafeReadMethod ||
        (method == 'POST' && retryPolicy == RequestRetryPolicy.transientRead);
    final isNetworkError =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.error is SocketException;
    final retryAttempt = requestOptions.extra['retryAttempt'] as int? ?? 0;

    final shouldRetry =
        retryPolicy == RequestRetryPolicy.transientRead ||
        (_retrySafeReadsByDefault && isSafeReadMethod);
    if (shouldRetry &&
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
