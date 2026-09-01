import 'package:passenger/src/features/home/home_routes.dart';

abstract final class AuthRoutes {
  static const String root = 'AuthRoot';
  static const String rootPath = '/';
  static const String signin = 'Signin';
  static const String signinPath = '/auth/signin';
  static const String signup = 'Signup';
  static const String signupPath = '/auth/signup';
  static const String forgotPassword = 'ForgotPassword';
  static const String forgotPasswordPath = '/auth/forgotpassword';
  static const String verifyOtp = 'VerifyOtp';
  static const String verifyOtpPath = '/auth/verifyotp';
  static const String resetPasswordConfirm = 'ResetPasswordConfirm';
  static const String resetPasswordConfirmPath = '/auth/resetpassword';
}

String? authRootRedirect(Uri uri) {
  return uri.path == AuthRoutes.rootPath ? HomeRoutes.fullHomePath : null;
}
