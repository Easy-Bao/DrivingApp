import 'package:foundation/foundation.dart';

class const AuthFailure([
  super.message = 'Your session has expired. Please sign in again to continue.',
]) extends Failure {}

class const InvalidCredentialsFailure() extends Failure {
  this : super('The email or password is incorrect.');
}

class const EmailAlreadyRegisteredFailure() extends Failure {
  this : super('This email is already registered.');
}
