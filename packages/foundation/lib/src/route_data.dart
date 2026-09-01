class RoutePayload._(this._values, this._queryParameters) {
  factory from({
    Object? extra,
    Map<String, String> queryParameters = const {},
  }) {
    final values = extra is Map
        ? Map<String, dynamic>.from(extra)
        : <String, dynamic>{};
    return RoutePayload._(values, queryParameters);
  }

  final Map<String, dynamic> _values;
  final Map<String, String> _queryParameters;

  T? object<T>(String key) {
    final value = _values[key];
    return value is T ? value : null;
  }

  String? string(String key, {String? queryKey}) {
    final fromExtra = _string(_values[key]);
    if (fromExtra != null) return fromExtra;
    return _string(_queryParameters[queryKey ?? key]);
  }

  double? doubleValue(String key, {String? queryKey}) {
    final fromExtra = _double(_values[key]);
    if (fromExtra != null) return fromExtra;
    return _double(_queryParameters[queryKey ?? key]);
  }

  int? intValue(String key, {String? queryKey}) {
    final fromExtra = _int(_values[key]);
    if (fromExtra != null) return fromExtra;
    return _int(_queryParameters[queryKey ?? key]);
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static double? _double(Object? value) {
    final result = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value.trim())
        : null;
    return result != null && result.isFinite ? result : null;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value is String ? int.tryParse(value.trim()) : null;
  }
}
