import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:driver/src/infrastructure/network/driver_auth_interceptor.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:foundation/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';

class ApiClient._() {
  static Dio create({
    required Uri baseUrl,
    required SessionStore sessionService,
    NetworkAvailabilityCoordinator? networkAvailability,
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
