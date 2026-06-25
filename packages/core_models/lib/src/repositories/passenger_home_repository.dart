/**
 * Contract: what the PassengerHome feature needs from the data layer.
 * Covers location resolution and recent place history.
 */
abstract class PassengerHomeRepository {
  /**
   * Resolves the current address for the given coordinates.
   */
  Future<String> resolveAddress({required double lat, required double lng});

  /**
   * Returns the passenger's recent destinations.
   */
  Future<List<Map<String, dynamic>>> getRecentLocations();
}
