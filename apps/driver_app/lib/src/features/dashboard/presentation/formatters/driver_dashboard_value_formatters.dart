double? dashboardFareInPesos(Map<String, dynamic> value) {
  final centavoValue =
      value['fare_centavos'] ??
      value['offered_fare_centavos'] ??
      value['proposed_fare_centavos'];
  if (centavoValue is num && centavoValue.isFinite) {
    return centavoValue.toDouble() / 100;
  }

  final legacyFare = value['fare'];
  if (legacyFare is num && legacyFare.isFinite) {
    return legacyFare.toDouble();
  }
  return null;
}

String? dashboardValueAsString(Object? value) {
  if (value == null) return null;
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String dashboardSentenceCase(Object? value, [String fallback = '—']) {
  final normalized = dashboardValueAsString(value);
  if (normalized == null) return fallback;
  final lowerCased = normalized.toLowerCase();
  return '${lowerCased.substring(0, 1).toUpperCase()}${lowerCased.substring(1)}';
}
