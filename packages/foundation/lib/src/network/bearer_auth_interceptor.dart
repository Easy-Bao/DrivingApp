import 'package:dio/dio.dart';
import 'package:foundation/src/auth/endpoints.dart';
import 'package:foundation/src/auth/token_provider.dart';

const authRetryAttemptExtraKey = 'authRetryAttempt';
const skipAuthRefreshExtraKey = 'skipAuthRefresh';
const skipAuthTokenExtraKey = 'skipAuthToken';

/// Applies origin-scoped access tokens and retries an unauthorized request once.
class BearerAuthInterceptor({
  required RefreshableTokenProvider tokenProvider,
  Dio? dio,
  Uri? allowedBaseUri,
}) extends Interceptor {
  final RefreshableTokenProvider _tokenProvider = tokenProvider;
  final Dio? _dio = dio;
  final Uri? _allowedBaseUri = allowedBaseUri;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAllowedOrigin(options.uri) ||
        options.extra[skipAuthTokenExtraKey] == true) {
      handler.next(options);
      return;
    }
    try {
      final token = await _tokenProvider.getToken();
      if (token != null && token.isNotEmpty) {
        _setAuthorizationHeader(options.headers, token);
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
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

    final dio = _dio;
    if (dio == null) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    final sentHeader = _readAuthorizationHeader(requestOptions.headers);
    String? accessToken;
    try {
      final latestToken = await _tokenProvider.getToken();
      if (latestToken != null &&
          latestToken.isNotEmpty &&
          sentHeader != null &&
          sentHeader != 'Bearer $latestToken') {
        accessToken = latestToken;
      } else {
        accessToken = await _tokenProvider.refreshAccessToken();
      }
    } catch (_) {
      handler.next(err);
      return;
    }
    if (accessToken == null || accessToken.isEmpty) {
      handler.next(err);
      return;
    }

    final updatedHeaders = Map<String, dynamic>.from(requestOptions.headers);
    _setAuthorizationHeader(updatedHeaders, accessToken);
    final retryOptions = requestOptions.copyWith(
      headers: updatedHeaders,
      extra: {...requestOptions.extra, authRetryAttemptExtraKey: true},
    );

    try {
      final response = await dio.fetch<Object?>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (unexpectedError, stackTrace) {
      handler.next(
        DioException(
          requestOptions: retryOptions,
          error: unexpectedError,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  bool _canRefresh(DioException error) {
    final requestOptions = error.requestOptions;
    final normalizedPath = requestOptions.uri.path.isNotEmpty
        ? requestOptions.uri.path
        : requestOptions.path.split('?').first;
    final isRefreshEndpoint =
        normalizedPath == AuthEndpoints.refresh ||
        normalizedPath.endsWith('${AuthEndpoints.refresh}/') ||
        normalizedPath.endsWith(AuthEndpoints.refresh);
    if (error.response?.statusCode != 401 ||
        _dio == null ||
        !_isAllowedOrigin(requestOptions.uri) ||
        requestOptions.extra[authRetryAttemptExtraKey] == true ||
        requestOptions.extra[skipAuthRefreshExtraKey] == true ||
        isRefreshEndpoint) {
      return false;
    }
    return true;
  }

  static void _setAuthorizationHeader(
    Map<String, dynamic> headers,
    String token,
  ) {
    headers.removeWhere((key, _) => key.toLowerCase() == 'authorization');
    headers['Authorization'] = 'Bearer $token';
  }

  static String? _readAuthorizationHeader(Map<String, dynamic> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'authorization' && entry.value is String) {
        return entry.value as String;
      }
    }
    return null;
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
