import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:driver_app/src/core/network/interceptors/auth_interceptor.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:foundation/foundation.dart';

class DioClient {
  DioClient._();

  static Dio create({
    required Uri baseUrl,
    required SecureSessionService sessionService,
    NetworkAvailabilityCoordinator? networkAvailability,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    final refreshClient = Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        sessionService,
        dio: dio,
        refreshClient: refreshClient,
        allowedBaseUri: baseUrl,
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        RequestMetricsInterceptor(HttpRequestMetrics.instance),
      );
      dio.interceptors.add(LoggingInterceptor());
    }
    dio.interceptors.add(IdempotencyInterceptor());
    if (networkAvailability != null) {
      dio.interceptors.add(NetworkAvailabilityInterceptor(networkAvailability));
    }
    dio.interceptors.add(RetryInterceptor(dio));

    return dio;
  }
}
