import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';

enum RequestRetryPolicy { transientRead }

const requestRetryPolicyExtraKey = 'requestRetryPolicy';
const retryAttemptExtraKey = 'retryAttempt';

typedef RetryDelay = Duration Function(int retryAttempt);

class RetryInterceptor(
  this.dio, {
  RetryDelay? retryDelay,
  this._retrySafeReadsByDefault = false,
}) extends Interceptor {
  static final Random _random = Random();

  final Dio dio;
  final bool _retrySafeReadsByDefault;
  final RetryDelay _retryDelay;

  this : _retryDelay = retryDelay ?? _defaultRetryDelay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.error is NetworkCircuitOpenException) {
      return super.onError(err, handler);
    }

    final requestOptions = err.requestOptions;
    final rawRetryPolicy = requestOptions.extra[requestRetryPolicyExtraKey];
    final retryPolicy = rawRetryPolicy is RequestRetryPolicy
        ? rawRetryPolicy
        : null;
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
    final rawAttempt = requestOptions.extra[retryAttemptExtraKey];
    final retryAttempt = rawAttempt is int ? rawAttempt : 0;

    final shouldRetry =
        retryPolicy == RequestRetryPolicy.transientRead ||
        (_retrySafeReadsByDefault && isSafeReadMethod);
    if (shouldRetry &&
        isRetryableMethod &&
        isNetworkError &&
        retryAttempt < 2 &&
        !(requestOptions.cancelToken?.isCancelled ?? false)) {
      await Future<void>.delayed(_retryDelay(retryAttempt + 1));
      if (requestOptions.cancelToken?.isCancelled ?? false) {
        return super.onError(err, handler);
      }
      final retryOptions = requestOptions.copyWith(
        extra: {
          ...requestOptions.extra,
          retryAttemptExtraKey: retryAttempt + 1,
        },
      );
      try {
        final response = await dio.fetch<Object?>(retryOptions);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        return handler.next(retryError);
      } catch (unexpectedError, stackTrace) {
        return handler.next(
          DioException(
            requestOptions: retryOptions,
            error: unexpectedError,
            stackTrace: stackTrace,
          ),
        );
      }
    }
    super.onError(err, handler);
  }

  static Duration _defaultRetryDelay(int retryAttempt) {
    final boundedAttempt = retryAttempt.clamp(1, 4);
    final baseMilliseconds = 250 * (1 << (boundedAttempt - 1));
    final jitterMilliseconds = _random.nextInt(126);
    return Duration(milliseconds: baseMilliseconds + jitterMilliseconds);
  }
}
