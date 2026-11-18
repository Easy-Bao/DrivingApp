double? _parseFiniteDouble(Object? value) {
  if (value is num) {
    final parsed = value.toDouble();
    return parsed.isFinite ? parsed : null;
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed != null && parsed.isFinite ? parsed : null;
  }
  return null;
}

double parseDouble(Object? value, [double defaultValue = 0.0]) =>
    _parseFiniteDouble(value) ?? defaultValue;

int parseInt(Object? value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.isFinite ? value.toInt() : defaultValue;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

String parseString(Object? value, [String defaultValue = '']) {
  if (value == null) return defaultValue;
  return value.toString();
}

abstract final class SafeParse {
  static double toDouble(Object? value, [double defaultValue = 0.0]) =>
      parseDouble(value, defaultValue);

  static double? toNullableDouble(Object? value) => _parseFiniteDouble(value);

  static int toInt(Object? value, [int defaultValue = 0]) =>
      parseInt(value, defaultValue);

  static String toStringValue(Object? value, [String defaultValue = '']) =>
      parseString(value, defaultValue);
}
