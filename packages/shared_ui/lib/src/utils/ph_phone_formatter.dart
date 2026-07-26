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
    if (digits.startsWith('0')) {
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

bool validatePhPhoneNumber(String rawDigits) {
  final String digits = rawDigits.replaceAll(RegExp(r'\D'), '');
  return digits.length == 10 && digits.startsWith('9');
}

String normalizePhPhoneNumber(String input) {
  final String digits = input.replaceAll(RegExp(r'\D'), '');
  final String local = digits.startsWith('63')
      ? digits.substring(2)
      : digits.startsWith('0')
          ? digits.substring(1)
          : digits;
  return '+63$local';
}
