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

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input parameters.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local storage cache.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'An unexpected server error occurred.']);
}
