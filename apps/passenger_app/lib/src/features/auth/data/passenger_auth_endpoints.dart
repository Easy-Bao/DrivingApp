/// HTTP paths owned by the passenger authentication workflow.
final class PassengerAuthEndpoints {
  PassengerAuthEndpoints._();

  static const String login = '/api/v1/auth/passenger/login';
  static const String register = '/api/v1/auth/passenger/register';
  static const String requestOtp = '/api/v1/auth/passenger/otp';
  static const String verifyOtp = '/api/v1/auth/passenger/verify-otp';
  static const String forgotPassword = '/api/v1/auth/passenger/forgot-password';
  static const String resetPassword = '/api/v1/auth/passenger/reset-password';
}
