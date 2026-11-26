import 'package:foundation/src/errors/failure.dart';

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Your session has expired. Sign in again.',
  ]);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure() : super('Incorrect email or password.');
}

class EmailAlreadyRegisteredFailure extends Failure {
  const EmailAlreadyRegisteredFailure()
    : super('This email is already registered.');
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure([super.message = 'Enter a valid email address.']);
}

class InvalidVerificationCodeFailure extends Failure {
  const InvalidVerificationCodeFailure([
    super.message = 'That verification code is invalid or expired. Try again.',
  ]);
}
