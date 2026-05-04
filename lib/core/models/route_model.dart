/// Represents a navigation route between two points.
/// Contains the polyline coordinates for map rendering, plus summary stats.
class RouteModel {
  final List<List<double>> polylinePoints; // [[lng, lat], ...]
  final double distanceKm;
  final Duration estimatedTime;
  final String summary;

  const RouteModel({
    required this.polylinePoints,
    required this.distanceKm,
    required this.estimatedTime,
    this.summary = '',
  });
}
