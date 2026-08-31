import 'package:shared_core/shared_core.dart';

String safeAuthFailureMessage(Failure failure) {
  return ErrorHandler.getErrorMessage(failure);
}
