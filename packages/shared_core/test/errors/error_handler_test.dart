import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('does not expose server failure details to the user', () {
    final message = ErrorHandler.getErrorMessage(
      const ServerFailure('database password leaked by the server'),
    );

    expect(
      message,
      'The service is temporarily unavailable. Please try again.',
    );
    expect(message, isNot(contains('database')));
  });

  test('maps infrastructure failures to safe user-facing messages', () {
    expect(
      ErrorHandler.getErrorMessage(
        const CacheFailure('sqlite table passenger_saved_places is missing'),
      ),
      'Saved information is unavailable right now. Please try again.',
    );
    expect(
      ErrorHandler.getErrorMessage(
        const NetworkFailure('SocketException: connection refused'),
      ),
      'Check your connection and try again.',
    );
    expect(
      ErrorHandler.getErrorMessage(
        const ValidationFailure('unexpected field passenger_internal_id'),
      ),
      isNot(contains('passenger_internal_id')),
    );
  });

  test('preserves the resolved-chat state message', () {
    expect(
      ErrorHandler.getErrorMessage(const ChatRoomLockedFailure()),
      'This chat has already been resolved.',
    );
  });
}
