abstract class const Failure(this.message) implements Exception {
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class const NetworkFailure([
  super.message = 'No internet connection or server timeout.',
]) extends Failure {}

class const ValidationFailure([super.message = 'Invalid input parameters.'])
    extends Failure {}

class const CacheFailure([
  super.message = 'Failed to load local storage cache.',
]) extends Failure {}

class const ServerFailure([
  super.message = 'An unexpected server error occurred.',
  final int? statusCode,
]) extends Failure {
  const factory ServerFailure.withStatusCode(String message, int statusCode) =
      ServerFailure;
}
