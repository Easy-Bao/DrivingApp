double? driverFareInPesos(Map<String, dynamic> value) {
  final amountValue =
      value['fare_amount'] ?? value['offered_fare'] ?? value['proposed_fare'];
  if (amountValue is num && amountValue.isFinite) {
    return amountValue.toDouble() / 100;
  }

  final legacyFare = value['fare'];
  if (legacyFare is num && legacyFare.isFinite) {
    return legacyFare.toDouble();
  }
  return null;
}

String? driverValueAsString(Object? value) {
  if (value == null) return null;
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String driverSentenceCase(Object? value, [String fallback = '—']) {
  final normalized = driverValueAsString(value);
  if (normalized == null) return fallback;
  final lowerCased = normalized.toLowerCase();
  return '${lowerCased.substring(0, 1).toUpperCase()}${lowerCased.substring(1)}';
}
