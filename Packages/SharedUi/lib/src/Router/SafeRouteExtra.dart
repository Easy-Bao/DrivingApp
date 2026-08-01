abstract class SafeRouteExtra {
  const SafeRouteExtra._();

  static Map<String, dynamic> asMap(dynamic extra) {
    if (extra is Map<String, dynamic>) {
      return extra;
    }
    if (extra is Map) {
      return Map<String, dynamic>.from(extra);
    }
    return <String, dynamic>{};
  }

  static String getString(
    Map<String, dynamic>? map,
    String key, [
    String fallback = '',
  ]) {
    if (map == null) return fallback;
    final value = map[key];
    if (value is String) return value;
    return value?.toString() ?? fallback;
  }

  static double getDouble(
    Map<String, dynamic>? map,
    String key, [
    double fallback = 0.0,
  ]) {
    if (map == null) return fallback;
    final value = map[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int getInt(
    Map<String, dynamic>? map,
    String key, [
    int fallback = 0,
  ]) {
    if (map == null) return fallback;
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
