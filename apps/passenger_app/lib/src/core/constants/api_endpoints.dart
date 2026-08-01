import 'package:passenger_app/src/core/constants/env_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String passengerLogin = '/auth/passenger/login';
  static const String passengerRegister = '/auth/passenger/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
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
