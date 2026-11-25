import 'package:foundation/src/network/offset_page.dart';

abstract class const SafeRouteExtra._() {
  static Map<String, dynamic> asMap(Object? extra) {
    if (extra is Map<String, dynamic>) {
      return extra;
    }
    if (extra is Map) {
      try {
        return decodeObjectMap(extra);
      } on FormatException {
        return <String, dynamic>{};
      }
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
    if (value is num || value is bool) return value.toString();
    return fallback;
  }

  static double getDouble(
    Map<String, dynamic>? map,
    String key, [
    double fallback = 0.0,
  ]) {
    if (map == null) return fallback;
    final value = map[key];
    if (value is num) {
      final parsed = value.toDouble();
      return parsed.isFinite ? parsed : fallback;
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed != null && parsed.isFinite ? parsed : fallback;
    }
    return fallback;
  }

  static int getInt(Map<String, dynamic>? map, String key, [int fallback = 0]) {
    if (map == null) return fallback;
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.isFinite ? value.toInt() : fallback;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
