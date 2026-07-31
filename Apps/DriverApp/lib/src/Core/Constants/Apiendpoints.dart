class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String driverStatus = '/driver/status';
  static const String activeBids = '/bids/active';
  static const String tripDetails = '/trips';
  static const String telemetryStream = '/telemetry/location';
}
