import 'dart:async';

import 'package:dio/dio.dart';
import 'package:driver_app/src/core/constants/api_endpoints.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';

class AuthInterceptor extends Interceptor {
  static const String _authRetryAttemptKey = 'authRetryAttempt';
  static const String _skipAuthRefreshKey = 'skipAuthRefresh';
  static const String _skipAuthTokenKey = 'skipAuthToken';

  final SecureSessionService _secureSessionService;
  final Dio? _dio;
  final Dio? _refreshClient;
  final Uri? _allowedBaseUri;

  Future<String?>? _refreshInFlight;

  AuthInterceptor(
    this._secureSessionService, {
    Dio? dio,
    Dio? refreshClient,
    Uri? allowedBaseUri,
  }) : _dio = dio,
       _refreshClient = refreshClient,
       _allowedBaseUri = allowedBaseUri;

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
        requestOptions.path.endsWith(ApiEndpoints.refreshToken)) {
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
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      await _secureSessionService.clearSession();
      return null;
    }

    try {
      final response = await refreshClient.post<Object?>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {_skipAuthTokenKey: true, _skipAuthRefreshKey: true},
        ),
      );
      final payload = _extractPayload(response.data);
      final accessToken = _stringValue(payload?['token']);
      if (accessToken.isEmpty) {
        await _secureSessionService.clearSession();
        return null;
      }

      final rotatedRefreshToken = _stringValue(payload?['refreshToken']);
      await _secureSessionService.saveToken(accessToken);
      await _secureSessionService.saveRefreshToken(
        rotatedRefreshToken.isEmpty ? refreshToken : rotatedRefreshToken,
      );
      return accessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _secureSessionService.clearSession();
      }
      return null;
    } catch (_) {
      await _secureSessionService.clearSession();
      return null;
    }
  }

  Map<String, dynamic>? _extractPayload(Object? responseData) {
    if (responseData is! Map) return null;
    final data = responseData['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(responseData);
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
