/**
 * Domain entity representing a passenger's pinned location shortcut (e.g., "Home", "Campus").
 * Entirely decoupled from JSON parsing schemas and UI tap callbacks.
 */
class SavedPlace {
  final String label;
  final String iconName;
  final String? savedAddress;
  final double? latitude;
  final double? longitude;

  const SavedPlace({
    required this.label,
    required this.iconName,
    this.savedAddress,
    this.latitude,
    this.longitude,
  });

  /** Returns true if coordinates are present to skip the lookup flow. */
  bool get hasLocation => latitude != null && longitude != null;
}
