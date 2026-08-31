import 'package:foundation/src/errors/app_failure.dart';

class ErrorHandler {
  ErrorHandler._();

  static AppFailure getAppFailure(Object error, [StackTrace? stackTrace]) {
    return AppFailure.fromException(error, stackTrace);
  }

  static String getErrorMessage(Object error, [StackTrace? stackTrace]) {
    return getAppFailure(error, stackTrace).userMessage;
  }
}
