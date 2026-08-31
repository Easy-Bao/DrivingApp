import 'package:foundation/foundation.dart';

class AuthFailure extends Failure {
  const AuthFailure([
    super.message =
        'Your session has expired. Please sign in again to continue.',
  ]);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure()
    : super('The email or password is incorrect.');
}

class EmailAlreadyRegisteredFailure extends Failure {
  const EmailAlreadyRegisteredFailure()
    : super('This email is already registered.');
}
