import 'package:shared_core/src/errors/failures.dart';

class ErrorHandler {
  ErrorHandler._();

  String get componentName => 'shared-error-handler';

  static String getErrorMessage(Object error) {
    if (error is ServerFailure) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    if (error is Failure) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
