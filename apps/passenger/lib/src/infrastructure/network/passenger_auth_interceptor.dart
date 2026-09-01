import 'dart:async';

import 'package:dio/dio.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';

class PassengerAuthInterceptor(
  this._secureSessionService, {
  this._dio,
  this._refreshClient,
  this._allowedBaseUri,
  this._onSessionExpired,
}) extends Interceptor {
  static const String _authRetryAttemptKey = 'authRetryAttempt';
  static const String _skipAuthRefreshKey = 'skipAuthRefresh';
  static const String _skipAuthTokenKey = 'skipAuthToken';
  static const String _refreshTokenPath = '/api/v1/auth/refresh';

  final PassengerSessionStore _secureSessionService;
  final Dio? _dio;
  final Dio? _refreshClient;
  final Uri? _allowedBaseUri;
  final FutureOr<void> Function()? _onSessionExpired;

  Future<String?>? _refreshInFlight;
  bool _sessionExpiryNotified = false;

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
    final token = await _secureSessionService.readToken();
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

    final accessToken = await _refreshAccessToken();
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
        _refreshClient == null ||
        !_isAllowedOrigin(requestOptions.uri) ||
        requestOptions.extra[_authRetryAttemptKey] == true ||
        requestOptions.extra[_skipAuthRefreshKey] == true ||
        requestOptions.path.endsWith(_refreshTokenPath)) {
      return false;
    }
    return true;
  }

  Future<String?> _refreshAccessToken() {
    final pending = _refreshInFlight;
    if (pending != null) return pending;

    late final Future<String?> trackedRefresh;
    trackedRefresh = _performRefresh().whenComplete(() {
      if (identical(_refreshInFlight, trackedRefresh)) {
        _refreshInFlight = null;
      }
    });
    _refreshInFlight = trackedRefresh;
    return trackedRefresh;
  }

  Future<String?> _performRefresh() async {
    final refreshClient = _refreshClient;
    if (refreshClient == null) return null;

    final refreshToken = await _secureSessionService.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }

    try {
      final response = await refreshClient.post<Object?>(
        _refreshTokenPath,
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {_skipAuthTokenKey: true, _skipAuthRefreshKey: true},
        ),
      );
      final payload = _extractPayload(response.data);
      final accessToken = _stringValue(payload?['token']);
      if (accessToken.isEmpty) {
        await _expireSession();
        return null;
      }

      final rotatedRefreshToken = _stringValue(payload?['refreshToken']);
      await _secureSessionService.saveToken(accessToken);
      await _secureSessionService.saveRefreshToken(
        rotatedRefreshToken.isEmpty ? refreshToken : rotatedRefreshToken,
      );
      _sessionExpiryNotified = false;
      return accessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _expireSession();
      }
      return null;
    } catch (_) {
      // A timeout, connection loss, or malformed transient response must not
      // sign the user out. The refresh token can still recover the session on
      // the next authenticated request; only an explicit auth rejection above
      // proves that the session is no longer valid.
      return null;
    }
  }

  Map<String, dynamic>? _extractPayload(Object? responseData) {
    if (responseData is! Map) return null;
    final data = responseData['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(responseData);
  }

  Future<void> _expireSession() async {
    await _secureSessionService.clearSession();
    if (_sessionExpiryNotified) return;
    _sessionExpiryNotified = true;
    try {
      await _onSessionExpired?.call();
    } catch (_) {
      // Session storage has already been cleared; navigation can recover later.
    }
  }

  String _stringValue(Object? value) => value?.toString() ?? '';

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
