mixin PhoneNumberValidator {
  static final RegExp _phMobilePattern = RegExp(r'^(\+639|09)\d{9}$');

  static bool isValidPHNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return _phMobilePattern.hasMatch(clean);
  }

  static String normalizePHNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('63')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+63${cleaned.substring(1)}';
    return '+63$cleaned';
  }
}
