import 'package:shared_core/src/errors/failures.dart';

class ErrorHandler {
  ErrorHandler._();

  String get componentName => 'shared-error-handler';

  static String getErrorMessage(Object error) {
    if (error is ChatRoomLockedFailure) {
      return error.message;
    }
    if (error is EmailAlreadyRegisteredFailure) {
      return error.message;
    }
    if (error is AuthFailure) {
      return 'Your session has expired. Please sign in again.';
    }
    if (error is NetworkFailure) {
      return 'Check your connection and try again.';
    }
    if (error is CacheFailure) {
      return 'Saved information is unavailable right now. Please try again.';
    }
    if (error is ValidationFailure) {
      return 'We could not complete that request. Check the details and try again.';
    }
    if (error is ServerFailure) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    if (error is Failure) {
      return 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
