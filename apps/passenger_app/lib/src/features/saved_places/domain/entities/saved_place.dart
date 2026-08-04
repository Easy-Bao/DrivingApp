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

  bool get hasLocation => latitude != null && longitude != null;
}
