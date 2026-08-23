import 'package:passenger_app/src/core/constants/env_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String passengerLogin = '/api/v1/auth/passenger/login';
  static const String passengerRegister = '/api/v1/auth/passenger/register';
  static const String passengerOtp = '/api/v1/auth/passenger/otp';
  static const String verifyOtp = '/api/v1/auth/passenger/verify-otp';
  static const String forgotPassword = '/api/v1/auth/passenger/forgot-password';
  static const String resetPassword = '/api/v1/auth/passenger/reset-password';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String fareEstimate = '/api/v1/bids/fare';
  static const String createBooking = '/api/v1/bids';
  static const String searchPlaces = '/api/v1/location/search';

  static Uri buildChatWebSocketUri({required String roomId}) {
    final base = EnvConfig.webSocketBaseUri;
    return base.replace(
      path: '/api/v1/chat/ws',
      queryParameters: {'roomId': roomId},
    );
  }
}
