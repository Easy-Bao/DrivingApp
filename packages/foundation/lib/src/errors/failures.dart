abstract class Failure implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection or server timeout.',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed. Please sign in again.',
  ]);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure()
    : super('The submitted sign-in credentials are invalid.');
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input parameters.']);
}

class EmailAlreadyRegisteredFailure extends Failure {
  const EmailAlreadyRegisteredFailure()
    : super('This email is already registered.');
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local storage cache.']);
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure([super.message = 'An unexpected server error occurred.'])
    : statusCode = null;

  const ServerFailure.withStatusCode(super.message, this.statusCode);
}
