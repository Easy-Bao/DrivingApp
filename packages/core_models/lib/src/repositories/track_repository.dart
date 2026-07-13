/// Contract: what the TrackDriver feature needs from the data layer.
abstract class TrackRepository {
  /// Fetches a snap-to-road polyline between two coordinates.
  /// Returns a list of [lat, lng] pairs, or null if unavailable.
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });
}
