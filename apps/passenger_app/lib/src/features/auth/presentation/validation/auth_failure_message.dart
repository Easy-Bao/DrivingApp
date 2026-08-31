import 'package:foundation/foundation.dart';

String safeAuthFailureMessage(Failure failure) {
  return ErrorHandler.getErrorMessage(failure);
}
