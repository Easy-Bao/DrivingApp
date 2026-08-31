import 'package:foundation/foundation.dart';

String signInFailureMessage(Failure failure) {
  return ErrorHandler.getErrorMessage(failure);
}
