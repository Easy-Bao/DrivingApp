import 'package:passenger_app/src/core/constants/env_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String fareEstimate = '/bids/fare';
  static const String createBooking = '/bids/session';
  static const String searchPlaces = '/places/search';

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
