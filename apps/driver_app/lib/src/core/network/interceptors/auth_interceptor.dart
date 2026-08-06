import 'package:dio/dio.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureSessionService _secureSessionService;
  final Uri? _allowedBaseUri;

  AuthInterceptor(this._secureSessionService, {Uri? allowedBaseUri})
    : _allowedBaseUri = allowedBaseUri;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAllowedOrigin(options.uri)) {
      handler.next(options);
      return;
    }
    final token = await _secureSessionService.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
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
