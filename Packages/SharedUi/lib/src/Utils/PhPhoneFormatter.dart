import 'package:flutter/services.dart';

class PhPhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('63') && digits.length > 2) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length > 1) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

bool validatePhPhoneNumber(String rawInput) {
  String digits = rawInput.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('0') && digits.length == 11) {
    digits = digits.substring(1);
  }

  return digits.length == 10 && digits.startsWith('9');
}

String normalizePhPhoneNumber(String input) {
  String digits = input.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('63') && digits.length > 10) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0') && digits.length == 11) {
    digits = digits.substring(1);
  }

  return '+63$digits';
}
