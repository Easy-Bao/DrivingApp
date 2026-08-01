import 'package:driver_app/src/Core/Constants/EnvConfig.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String driverStatus = '/driver/status';
  static const String activeBids = '/bids/active';
  static const String tripDetails = '/trips';
  static const String telemetryStream = '/telemetry/location';

  static Uri buildChatWebSocketUri({
    required String roomId,
    required String userId,
  }) {
    final base = EnvConfig.webSocketBaseUri;
    return base.replace(
      path: '/chat/ws',
      queryParameters: {'roomId': roomId, 'userId': userId},
    );
  }
}
