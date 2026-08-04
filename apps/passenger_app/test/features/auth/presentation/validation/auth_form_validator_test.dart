import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_form_validator.dart';

void main() {
  group('AuthFormValidator.email', () {
    test('accepts a normalized email address', () {
      expect(authFormValidator.email('passenger@example.com'), isNull);
    });

    test('returns a field-specific message for invalid input', () {
      expect(
        authFormValidator.email('not-an-email'),
        'Enter a valid email address.',
      );
    });
  });

  group('AuthFormValidator.phone', () {
    test('accepts a Philippine mobile number', () {
      expect(authFormValidator.phone('09171234567'), isNull);
    });

    test('rejects a non-Philippine mobile number', () {
      expect(
        authFormValidator.phone('12345'),
        'Enter a valid Philippine mobile number.',
      );
    });
  });

  test('keeps password and confirmation messages consistent across forms', () {
    expect(authFormValidator.password('short'), 'Use at least 8 characters.');
    expect(
      authFormValidator.confirmation('password123', 'different'),
      'Passwords do not match.',
    );
  });
}
