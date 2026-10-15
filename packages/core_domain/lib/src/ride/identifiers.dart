/// Compile-time typed identifiers and values used by ride workflows.
///
/// Extension types preserve the representation of their underlying values at
/// runtime while preventing accidental mixing of identifiers or units at the
/// API boundary.
extension type const PassengerId(String raw) {
  static PassengerId? tryParse(Object? value) {
    final normalized = _normalizedIdentifier(value);
    return normalized == null ? null : PassengerId(normalized);
  }

  String get normalized => raw.trim();

  bool get isValid => normalized.isNotEmpty;
}

extension type const DriverId(String raw) {
  static DriverId? tryParse(Object? value) {
    final normalized = _normalizedIdentifier(value);
    return normalized == null ? null : DriverId(normalized);
  }

  String get normalized => raw.trim();

  bool get isValid => normalized.isNotEmpty;
}

extension type const BookingSessionId(String raw) {
  static BookingSessionId? tryParse(Object? value) {
    final normalized = _normalizedIdentifier(value);
    return normalized == null ? null : BookingSessionId(normalized);
  }

  String get normalized => raw.trim();

  bool get isValid => normalized.isNotEmpty;
}

extension type const BookingOfferId(String raw) {
  static BookingOfferId? tryParse(Object? value) {
    final normalized = _normalizedIdentifier(value);
    return normalized == null ? null : BookingOfferId(normalized);
  }

  String get normalized => raw.trim();

  bool get isValid => normalized.isNotEmpty;
}

extension type const RideId(String raw) {
  static RideId? tryParse(Object? value) {
    final normalized = _normalizedIdentifier(value);
    return normalized == null ? null : RideId(normalized);
  }

  String get normalized => raw.trim();

  bool get isValid => normalized.isNotEmpty;
}

/// A named record keeps coordinates allocation-free while making latitude and
/// longitude ordering explicit at call sites.
typedef RideCoordinates = (double latitude, double longitude);

extension type const DistanceKm(double value) {
  bool get isValid => value.isFinite && value >= 0;

  bool get isShortHop => isValid && value <= 3;

  double get meters => value * 1000;

  String get label => '${value.toStringAsFixed(1)} km';

  DistanceKm operator +(DistanceKm other) => DistanceKm(value + other.value);
}

extension type const FareCents(int value) {
  bool get isValid => value > 0;

  double get amount => value / 100;

  String get displayAmount => '₱${amount.toStringAsFixed(2)}';

  FareCents operator +(FareCents other) => FareCents(value + other.value);
}

bool isValidRideCoordinates(RideCoordinates coordinates) {
  final (latitude, longitude) = coordinates;
  return latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

String? _normalizedIdentifier(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
