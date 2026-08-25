import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_failure_message.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('maps infrastructure failures to safe client-owned copy', () {
    expect(
      safeAuthFailureMessage(
        const ServerFailure('database password leaked by the server'),
      ),
      'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
    );
  });

  test(
    'preserves an actionable email conflict without exposing server text',
    () {
      expect(
        safeAuthFailureMessage(const EmailAlreadyRegisteredFailure()),
        'This email is already registered.',
      );
    },
  );
}
