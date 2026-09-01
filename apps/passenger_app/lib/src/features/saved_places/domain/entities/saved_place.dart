class const SavedPlace({
  required this.label,
  required this.iconName,
  this.savedAddress,
  this.latitude,
  this.longitude,
  this.isDefault = false,
}) {
  final String label;
  final String iconName;
  final String? savedAddress;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  bool get hasLocation => latitude != null && longitude != null;

  SavedPlace copyWith({
    String? label,
    String? iconName,
    String? savedAddress,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return SavedPlace(
      label: label ?? this.label,
      iconName: iconName ?? this.iconName,
      savedAddress: savedAddress ?? this.savedAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
