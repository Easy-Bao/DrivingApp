import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/network/auth_interceptor.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:sentry_dio/sentry_dio.dart';

class ApiClient._() {
  static Dio create({
    required Uri baseUrl,
    required SessionStore sessionService,
    NetworkAvailabilityCoordinator? networkAvailability,
    FutureOr<void> Function()? onSessionExpired,
    RefreshableTokenProvider? tokenProvider,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    final refreshClient = tokenProvider == null
        ? Dio(
            BaseOptions(
              baseUrl: baseUrl.toString(),
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ),
          )
        : null;

    dio.interceptors.add(
      AuthInterceptor(
        sessionService,
        dio: dio,
        refreshClient: refreshClient,
        allowedBaseUri: baseUrl,
        onSessionExpired: onSessionExpired,
        tokenProvider: tokenProvider,
      ),
    );
    if (kDebugMode || kProfileMode) {
      dio.interceptors.add(
        RequestMetricsInterceptor(HttpRequestMetrics.instance),
      );
    }
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }
    dio.interceptors.add(IdempotencyInterceptor());
    if (networkAvailability != null) {
      dio.interceptors.add(NetworkAvailabilityInterceptor(networkAvailability));
    }
    dio.interceptors.add(RetryInterceptor(dio, retrySafeReadsByDefault: true));
    dio.addSentry();

    return dio;
  }
}
