import 'dart:io';
import 'package:dio/dio.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';

/// Preconfigured HTTP client builder utilizing [Dio].
///
/// Attaches JWT headers dynamically from [SecureSessionService] and provides
/// transparent retry policies when network dropouts occur.
class DioClient {
  DioClient._();

  /// Builds a [Dio] instance preconfigured with custom interceptors for session management.
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

    dio.interceptors.add(_AuthTokenInterceptor(sessionService: sessionService));
    dio.interceptors.add(_RetryOnNetworkFailureInterceptor(dio: dio));

    return dio;
  }
}

class _AuthTokenInterceptor extends Interceptor {
  final SecureSessionService _sessionService;

  _AuthTokenInterceptor({required SecureSessionService sessionService})
    : _sessionService = sessionService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _sessionService.readAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}

class _RetryOnNetworkFailureInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries = 3;
  final Duration retryDelay = const Duration(seconds: 2);

  _RetryOnNetworkFailureInterceptor({required this.dio});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // Retry only on network-related timeouts, connection dropouts, or SocketExceptions.
    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.error is SocketException);

    final retryAttempt = requestOptions.extra['retryAttempt'] as int? ?? 0;

    if (isNetworkError && retryAttempt < maxRetries) {
      final nextAttempt = retryAttempt + 1;
      requestOptions.extra['retryAttempt'] = nextAttempt;

      await Future.delayed(retryDelay);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (_) {
        // Let the sequential error chain catch subsequent failure attempts.
      }
    }
    super.onError(err, handler);
  }
}
