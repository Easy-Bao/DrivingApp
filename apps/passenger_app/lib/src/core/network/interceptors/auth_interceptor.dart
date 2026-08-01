import 'package:dio/dio.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureSessionService _secureSessionService;
  AuthInterceptor(this._secureSessionService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureSessionService.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
