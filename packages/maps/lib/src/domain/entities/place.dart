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
    final {
      'id': rawId,
      'name': rawName,
      'full_address': rawFullAddress,
      'latitude': rawLatitude,
      'longitude': rawLongitude,
      'category': rawCategory,
      'distance_km': rawDistanceKm,
      'match_type': rawMatchType,
      'distance_meters': rawDistanceMeters,
      'confidence': rawConfidence,
      'context': rawContext,
    } = _canonicalPayload(
      json,
    );

    return Place(
      id: rawId?.toString() ?? '',
      name: rawName?.toString() ?? '',
      fullAddress: rawFullAddress?.toString() ?? '',
      latitude: _numberOrDefault(rawLatitude, 'latitude'),
      longitude: _numberOrDefault(rawLongitude, 'longitude'),
      category: rawCategory?.toString(),
      distanceKm: _nullableNumber(rawDistanceKm, 'distance_km'),
      matchType: rawMatchType?.toString(),
      distanceMeters: _nullableNumber(rawDistanceMeters, 'distance_meters'),
      confidence: _nullableNumber(rawConfidence, 'confidence'),
      context: _contextMap(rawContext),
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

Map<String, Object?> _canonicalPayload(Map<String, dynamic> json) => {
  'id': json['id'],
  'name': json['name'],
  'full_address':
      json['fullAddress'] ?? json['full_address'] ?? json['address'],
  'latitude': json['latitude'] ?? json['lat'],
  'longitude': json['longitude'] ?? json['lng'],
  'category': json['category'],
  'distance_km': json['distanceKm'] ?? json['distance_km'],
  'match_type': json['matchType'] ?? json['match_type'],
  'distance_meters': json['distanceMeters'] ?? json['distance_meters'],
  'confidence': json['confidence'],
  'context': json['context'],
};

double _numberOrDefault(Object? value, String field) {
  return switch (value) {
    null => 0,
    final num number => number.toDouble(),
    final String text => _parseStringNumber(text, field),
    _ => throw FormatException('Place $field must be numeric.'),
  };
}

double? _nullableNumber(Object? value, String field) {
  return switch (value) {
    null => null,
    final num number => number.toDouble(),
    final String text => _parseStringNumber(text, field),
    _ => throw FormatException('Place $field must be numeric.'),
  };
}

double _parseStringNumber(String value, String field) {
  final parsed = double.tryParse(value);
  if (parsed == null) {
    throw FormatException('Place $field must be numeric.');
  }
  return parsed;
}

Map<String, String> _contextMap(Object? value) {
  final context = <String, String>{};
  if (value is Map) {
    value.forEach((key, item) {
      if (item != null) context[key.toString()] = item.toString();
    });
  }
  return context;
}
