import 'dart:math' as math;

/// Pure geographic calculations shared across map data and presentation layers.
class GeoMath._() {
  static const double earthRadiusKm = 6371.0;

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  static double haversineKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    final deltaLatitude = _toRadians(latitude2 - latitude1);
    final deltaLongitude = _toRadians(longitude2 - longitude1);

    final haversineA =
        (math.sin(deltaLatitude / 2.0) * math.sin(deltaLatitude / 2.0) +
                math.cos(_toRadians(latitude1)) *
                    math.cos(_toRadians(latitude2)) *
                    math.sin(deltaLongitude / 2.0) *
                    math.sin(deltaLongitude / 2.0))
            .clamp(0.0, 1.0)
            .toDouble();

    return earthRadiusKm * 2.0 * math.asin(math.sqrt(haversineA));
  }

  static bool isValidCoordinate(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
