import 'package:equatable/equatable.dart';

class PlaceModel extends Equatable {
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

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fullAddress:
          json['fullAddress'] as String? ??
          json['full_address'] as String? ??
          '',
      latitude: (json['latitude'] as num? ?? json['lat'] as num? ?? 0.0)
          .toDouble(),
      longitude: (json['longitude'] as num? ?? json['lng'] as num? ?? 0.0)
          .toDouble(),
      category: json['category'] as String?,
      distanceKm: (json['distanceKm'] as num? ?? json['distance_km'] as num?)
          ?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'distanceKm': distanceKm,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    fullAddress,
    latitude,
    longitude,
    category,
    distanceKm,
  ];
}
