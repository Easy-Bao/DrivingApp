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
}
