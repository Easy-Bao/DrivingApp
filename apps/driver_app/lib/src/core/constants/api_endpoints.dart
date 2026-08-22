import 'package:driver_app/src/core/constants/env_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String driverLogin = '/api/v1/auth/driver/login';
  static const String driverForgotPassword =
      '/api/v1/auth/driver/forgot-password';
  static const String driverResetPassword =
      '/api/v1/auth/driver/reset-password';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String driverStatus = '/api/v1/driver/status';
  static const String activeBids = '/api/v1/bids/active';
  static const String tripDetails = '/api/v1/trips';
  static const String telemetryStream = '/api/v1/telemetry/location';

  static Uri buildChatWebSocketUri({
    required String roomId,
    required String userId,
  }) {
    final base = EnvConfig.webSocketBaseUri;
    return base.replace(
      path: '/api/v1/chat/ws',
      queryParameters: {'roomId': roomId, 'userId': userId},
    );
  }
}
