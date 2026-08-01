class PhoneNumberValidator {
  static bool isValidPHNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return clean.startsWith('+639') || clean.startsWith('09');
  }
}
