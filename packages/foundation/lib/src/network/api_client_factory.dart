import 'dart:async';

import 'package:dio/dio.dart';
import 'package:foundation/src/auth/token_provider.dart';
import 'package:foundation/src/network/availability_coordinator.dart';
import 'package:foundation/src/network/bearer_auth_interceptor.dart';
import 'package:foundation/src/network/idempotency_interceptor.dart';
import 'package:foundation/src/network/logging_interceptor.dart';
import 'package:foundation/src/network/request_metrics.dart';
import 'package:foundation/src/network/retry_interceptor.dart';

/// Minimal credential storage contract required by shared HTTP auth plumbing.
abstract interface class SessionTokenStore {
  Future<String?> readToken();

  Future<String?> readRefreshToken();

  Future<void> saveToken(String token);

  Future<void> saveRefreshToken(String token);

  Future<void> clearSession();
}

/// Builds the standardized resilient Dio pipeline shared by client apps.
class ApiClientFactory._() {
  static const Duration defaultTimeout = Duration(seconds: 15);

  static BearerAuthInterceptor createAuthInterceptor({
    required SessionTokenStore sessionStore,
    Dio? dio,
    Dio? refreshClient,
    Uri? allowedBaseUri,
    FutureOr<void> Function()? onSessionExpired,
    RefreshableTokenProvider? tokenProvider,
  }) {
    final resolvedProvider =
        tokenProvider ??
        RefreshableTokenProvider(
          readAccessToken: sessionStore.readToken,
          readRefreshToken: sessionStore.readRefreshToken,
          saveAccessToken: sessionStore.saveToken,
          saveRefreshToken: sessionStore.saveRefreshToken,
          clearSession: sessionStore.clearSession,
          refreshClient: refreshClient,
          onSessionExpired: onSessionExpired,
        );
    return BearerAuthInterceptor(
      tokenProvider: resolvedProvider,
      dio: dio,
      allowedBaseUri: allowedBaseUri,
    );
  }

  static Dio create({
    required Uri baseUrl,
    required SessionTokenStore sessionStore,
    NetworkAvailabilityCoordinator? networkAvailability,
    FutureOr<void> Function()? onSessionExpired,
    RefreshableTokenProvider? tokenProvider,
    bool enableMetrics = false,
    bool enableDebugLogging = false,
    Duration timeout = defaultTimeout,
    void Function(Dio dio)? configureDio,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
      ),
    );

    final refreshClient = tokenProvider == null
        ? Dio(
            BaseOptions(
              baseUrl: baseUrl.toString(),
              connectTimeout: timeout,
              receiveTimeout: timeout,
              sendTimeout: timeout,
            ),
          )
        : null;

    dio.interceptors.add(
      createAuthInterceptor(
        sessionStore: sessionStore,
        dio: dio,
        refreshClient: refreshClient,
        allowedBaseUri: baseUrl,
        onSessionExpired: onSessionExpired,
        tokenProvider: tokenProvider,
      ),
    );
    if (enableMetrics) {
      dio.interceptors.add(
        RequestMetricsInterceptor(HttpRequestMetrics.instance),
      );
    }
    if (enableDebugLogging) {
      dio.interceptors.add(LoggingInterceptor());
    }
    dio.interceptors.add(IdempotencyInterceptor());
    if (networkAvailability != null) {
      dio.interceptors.add(NetworkAvailabilityInterceptor(networkAvailability));
    }
    dio.interceptors.add(RetryInterceptor(dio, retrySafeReadsByDefault: true));
    configureDio?.call(dio);

    return dio;
  }
}
