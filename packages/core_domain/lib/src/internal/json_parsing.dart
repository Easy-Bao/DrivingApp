String readStringValue(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
}

double? readNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) {
    final parsed = value.toDouble();
    return parsed.isFinite ? parsed : null;
  }
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed.isFinite ? parsed : null;
  }
  return null;
}

String? readTrimmedNonEmpty(Object? value) {
  final normalized = readStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime? readNullableUtcDateTime(Object? value) {
  final normalized = readTrimmedNonEmpty(value);
  return normalized == null ? null : DateTime.tryParse(normalized)?.toUtc();
}

bool? readNullableBool(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    };
  }
  return null;
}
