import 'package:foundation/src/errors/failure.dart';

class ErrorHandler._() {
  static AppFailure getAppFailure(Object error, [StackTrace? stackTrace]) {
    return AppFailure.fromException(error, stackTrace);
  }

  static String getErrorMessage(Object error, [StackTrace? stackTrace]) {
    return getAppFailure(error, stackTrace).userMessage;
  }
}
