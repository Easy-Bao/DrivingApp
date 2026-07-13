/// Domain-level base failure interface representing an app error boundary.
abstract class Failure implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Represents connection timeouts, socket issues, or gateway host failure.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection or server timeout.',
  ]);
}

/// Represents expired sessions, bad credentials, or invalid authentication tokens.
class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed. Please sign in again.',
  ]);
}

/// Represents bad user input, request formats, or invalid payload arguments.
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input parameters.']);
}

/// Represents errors during local DB or key-value store lookups/writes.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local storage cache.']);
}

/// Represents unexpected or unmapped internal microservice exceptions (500).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'An unexpected server error occurred.']);
}
