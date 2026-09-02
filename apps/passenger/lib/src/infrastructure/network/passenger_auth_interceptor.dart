import 'dart:async';

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';

class PassengerAuthInterceptor(
  PassengerSessionStore secureSessionService, {
  Dio? dio,
  Dio? refreshClient,
  Uri? allowedBaseUri,
  FutureOr<void> Function()? onSessionExpired,
  RefreshableTokenProvider? tokenProvider,
}) extends Interceptor {
  static const String _authRetryAttemptKey = 'authRetryAttempt';
  static const String _skipAuthRefreshKey = 'skipAuthRefresh';
  static const String _skipAuthTokenKey = 'skipAuthToken';
  static const String _refreshTokenPath = '/api/v1/auth/refresh';

  final Dio? _dio = dio;
  final Uri? _allowedBaseUri = allowedBaseUri;
  final RefreshableTokenProvider _tokenProvider =
      tokenProvider ??
      RefreshableTokenProvider(
        readAccessToken: secureSessionService.readToken,
        readRefreshToken: secureSessionService.readRefreshToken,
        saveAccessToken: secureSessionService.saveToken,
        saveRefreshToken: secureSessionService.saveRefreshToken,
        clearSession: secureSessionService.clearSession,
        refreshClient: refreshClient,
        onSessionExpired: onSessionExpired,
      );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAllowedOrigin(options.uri) ||
        options.extra[_skipAuthTokenKey] == true) {
      handler.next(options);
      return;
    }
    final token = await _tokenProvider.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_canRefresh(err)) {
      handler.next(err);
      return;
    }

    final accessToken = await _tokenProvider.refreshAccessToken();
    final dio = _dio;
    if (accessToken == null || dio == null) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    final retryOptions = requestOptions.copyWith(
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $accessToken',
      },
      extra: {...requestOptions.extra, _authRetryAttemptKey: true},
    );

    try {
      final response = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _canRefresh(DioException error) {
    final requestOptions = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        _dio == null ||
        !_isAllowedOrigin(requestOptions.uri) ||
        requestOptions.extra[_authRetryAttemptKey] == true ||
        requestOptions.extra[_skipAuthRefreshKey] == true ||
        requestOptions.path.endsWith(_refreshTokenPath)) {
      return false;
    }
    return true;
  }

  bool _isAllowedOrigin(Uri requestUri) {
    final allowed = _allowedBaseUri;
    if (allowed == null) return true;
    return requestUri.scheme == allowed.scheme &&
        requestUri.host == allowed.host &&
        _effectivePort(requestUri) == _effectivePort(allowed);
  }

  int _effectivePort(Uri uri) {
    if (uri.hasPort) return uri.port;
    return switch (uri.scheme) {
      'https' => 443,
      'http' => 80,
      _ => 0,
    };
  }
}
