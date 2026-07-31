double parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

String parseString(dynamic value, [String defaultValue = '']) {
  if (value == null) return defaultValue;
  return value.toString();
}

abstract class SafeParse {
  static double toDouble(dynamic value, [double defaultValue = 0.0]) =>
      parseDouble(value, defaultValue);

  static int toInt(dynamic value, [int defaultValue = 0]) =>
      parseInt(value, defaultValue);

  static String toStringValue(dynamic value, [String defaultValue = '']) =>
      parseString(value, defaultValue);
}
