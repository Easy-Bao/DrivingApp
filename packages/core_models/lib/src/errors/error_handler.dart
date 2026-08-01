import 'package:core_models/src/errors/failures.dart';

class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is Failure) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
