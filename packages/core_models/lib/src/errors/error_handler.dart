import 'failures.dart';

/// Global utility mapping [Failure] objects to localized, user-facing error messages.
class ErrorHandler {
  /// Maps a given domain-level [Failure] or fallback exception to a clean UI string.
  static String getErrorMessage(Object error) {
    if (error is Failure) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
