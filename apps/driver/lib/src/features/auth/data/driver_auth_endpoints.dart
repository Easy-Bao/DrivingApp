/// HTTP paths owned by the driver authentication workflow.
final class DriverAuthEndpoints._() {
  static const String login = '/api/v1/auth/driver/login';
  static const String forgotPassword = '/api/v1/auth/driver/forgot-password';
  static const String resetPassword = '/api/v1/auth/driver/reset-password';
}
