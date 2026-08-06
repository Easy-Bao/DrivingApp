abstract final class AuthRoutes {
  static const String root = 'AuthRoot';
  static const String signin = 'Signin';
  static const String signup = 'Signup';
  static const String forgotPassword = 'ForgotPassword';
  static const String verifyOtp = 'VerifyOtp';
  static const String resetPasswordConfirm = 'ResetPasswordConfirm';

  static String? rootRedirect(Uri uri) {
    return uri.path == '/' ? '/passenger/location-gate' : null;
  }
}
