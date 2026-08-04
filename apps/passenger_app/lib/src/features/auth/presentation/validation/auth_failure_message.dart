import 'package:shared_core/shared_core.dart';

String safeAuthFailureMessage(Failure failure) {
  if (failure is EmailAlreadyRegisteredFailure) {
    return 'This email is already registered. Try signing in or use another email.';
  }
  if (failure is AuthFailure) {
    return 'The email or password is incorrect.';
  }
  if (failure is NetworkFailure) {
    return 'Cannot reach the authentication service. Check your connection and try again.';
  }
  if (failure is ValidationFailure) {
    return 'Please review the information and try again.';
  }
  return 'Authentication is temporarily unavailable. Please try again.';
}
