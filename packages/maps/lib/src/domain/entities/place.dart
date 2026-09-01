import 'package:equatable/equatable.dart';

class const Place({
  required this.id,
  required this.name,
  required this.fullAddress,
  required this.latitude,
  required this.longitude,
  this.category,
  this.distanceKm,
  this.matchType,
  this.distanceMeters,
  this.confidence,
  this.context = const {},
}) extends Equatable {
  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? category;
  final double? distanceKm;
  final String? matchType;
  final double? distanceMeters;
  final double? confidence;
  final Map<String, String> context;

  String get displayName {
    final value = name.trim().isNotEmpty ? name.trim() : fullAddress.trim();
    final type = matchType?.trim().toLowerCase();
    final distance = distanceMeters ?? 0;
    if (value.isEmpty ||
        distance <= 0 ||
        type == null ||
        type.isEmpty ||
        type == 'direct') {
      return value;
    }
    if (value.toLowerCase().startsWith('near ')) {
      return value;
    }
    return 'Near $value';
  }

  factory fromJson(Map<String, dynamic> json) {
    final context = <String, String>{};
    final rawContext = json['context'];
    if (rawContext is Map) {
      rawContext.forEach((key, value) {
        if (value != null) {
          context[key.toString()] = value.toString();
        }
      });
    }

    return Place(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fullAddress:
          json['fullAddress']?.toString() ??
          json['full_address']?.toString() ??
          json['address']?.toString() ??
          '',
      latitude: (json['latitude'] as num? ?? json['lat'] as num? ?? 0.0)
          .toDouble(),
      longitude: (json['longitude'] as num? ?? json['lng'] as num? ?? 0.0)
          .toDouble(),
      category: json['category']?.toString(),
      distanceKm: (json['distanceKm'] as num? ?? json['distance_km'] as num?)
          ?.toDouble(),
      matchType:
          json['matchType']?.toString() ?? json['match_type']?.toString(),
      distanceMeters:
          (json['distanceMeters'] as num? ?? json['distance_meters'] as num?)
              ?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      context: context,
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
      'matchType': matchType,
      'distanceMeters': distanceMeters,
      'confidence': confidence,
      'context': context,
    };
  }

  Place copyWith({
    String? id,
    String? name,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? category,
    double? distanceKm,
    String? matchType,
    double? distanceMeters,
    double? confidence,
    Map<String, String>? context,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      distanceKm: distanceKm ?? this.distanceKm,
      matchType: matchType ?? this.matchType,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      confidence: confidence ?? this.confidence,
      context: context ?? this.context,
    );
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
    matchType,
    distanceMeters,
    confidence,
    context,
  ];
}
