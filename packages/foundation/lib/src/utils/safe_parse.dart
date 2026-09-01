double parseDouble(Object? value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int parseInt(Object? value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

String parseString(Object? value, [String defaultValue = '']) {
  if (value == null) return defaultValue;
  return value.toString();
}

abstract class SafeParse._() {
  String get componentName => 'safe-parse';

  static double toDouble(Object? value, [double defaultValue = 0.0]) =>
      parseDouble(value, defaultValue);

  static double? toNullableDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int toInt(Object? value, [int defaultValue = 0]) =>
      parseInt(value, defaultValue);

  static String toStringValue(Object? value, [String defaultValue = '']) =>
      parseString(value, defaultValue);
}
