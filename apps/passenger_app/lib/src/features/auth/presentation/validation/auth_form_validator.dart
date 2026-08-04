import 'package:passenger_app/src/core/utils/phone_number_validator.dart';

final class AuthFormValidator {
  const AuthFormValidator();

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  String? name(String value) {
    if (value.trim().isEmpty) return 'Enter your full name.';
    return null;
  }

  String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? phone(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Enter your phone number.';
    if (!PhoneNumberValidator.isValidPHNumber(normalized)) {
      return 'Enter a valid Philippine mobile number.';
    }
    return null;
  }

  String? password(String value, {int minimumLength = 8}) {
    if (value.isEmpty) return 'Enter your password.';
    if (value.length < minimumLength) {
      return 'Use at least $minimumLength characters.';
    }
    return null;
  }

  String? confirmation(String password, String confirmation) {
    if (confirmation.isEmpty) return 'Confirm your password.';
    if (password != confirmation) return 'Passwords do not match.';
    return null;
  }
}

const authFormValidator = AuthFormValidator();
