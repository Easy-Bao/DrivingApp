import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:passenger_app/src/core/network/interceptors/auth_interceptor.dart';
import 'package:passenger_app/src/core/network/interceptors/logging_interceptor.dart';
import 'package:passenger_app/src/core/network/interceptors/retry_interceptor.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';

class DioClient {
  DioClient._();

  static Dio create({
    required Uri baseUrl,
    required SecureSessionService sessionService,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(AuthInterceptor(sessionService));
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }
    dio.interceptors.add(RetryInterceptor(dio));

    return dio;
  }
}
