import 'package:shared_core/shared_core.dart';

String signInFailureMessage(Failure failure) {
  return ErrorHandler.getErrorMessage(failure);
}
