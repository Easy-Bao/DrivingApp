/// Represents a geographic place from geocoding results.
/// Used across search, destination preview, and activity detail screens.
class PlaceModel {
  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? category;
  final double? distanceKm;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.category,
    this.distanceKm,
  });

  PlaceModel copyWith({
    String? id,
    String? name,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? category,
    double? distanceKm,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
