import 'package:shared_core/shared_core.dart';

String signInFailureMessage(Failure failure) {
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
