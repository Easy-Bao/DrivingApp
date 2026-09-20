abstract class const Failure(this.message) implements Exception {
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class const NetworkFailure([
  super.message = "Couldn't connect. Check your internet connection and try again.",
]) extends Failure {}

class const ValidationFailure([super.message = 'Check the highlighted fields.'])
    extends Failure {}

class const CacheFailure([
  super.message = 'Saved information is unavailable. Try again.',
]) extends Failure {}

class const ServerFailure([
  super.message = 'Something went wrong. Try again.',
  final int? statusCode,
]) extends Failure {
  const factory withStatusCode(String message, int statusCode) = ServerFailure;
}
