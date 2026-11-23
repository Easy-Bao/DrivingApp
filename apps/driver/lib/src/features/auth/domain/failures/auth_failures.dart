import 'package:foundation/foundation.dart';

class const AuthFailure([
  super.message = 'Your session has expired. Sign in again.',
]) extends Failure {}

class const InvalidCredentialsFailure() extends Failure {
  this : super('Incorrect email or password.');
}

class const EmailAlreadyRegisteredFailure() extends Failure {
  this : super('This email is already registered.');
}

class const InvalidEmailFailure([
  super.message = 'Enter a valid email address.',
]) extends Failure {}

class const InvalidVerificationCodeFailure([
  super.message = 'That verification code is invalid or expired. Try again.',
]) extends Failure {}
