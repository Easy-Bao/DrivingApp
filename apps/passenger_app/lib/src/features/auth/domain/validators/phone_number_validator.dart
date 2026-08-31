mixin PhoneNumberValidator {
  static bool isValidPHNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return clean.startsWith('+639') || clean.startsWith('09');
  }

  static String normalizePHNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('63')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+63${cleaned.substring(1)}';
    return '+63$cleaned';
  }
}
