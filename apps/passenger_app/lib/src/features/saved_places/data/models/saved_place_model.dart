import 'dart:convert';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:foundation/foundation.dart';

class SavedPlaceModel extends SavedPlace {
  const SavedPlaceModel({
    required super.label,
    required super.iconName,
    super.savedAddress,
    super.latitude,
    super.longitude,
    super.isDefault,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'iconName': iconName,
    if (savedAddress != null) 'savedAddress': savedAddress,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'isDefault': isDefault,
  };

  factory SavedPlaceModel.fromJson(Map<String, dynamic> json) {
    final label = SafeParse.toStringValue(json['label']).trim();
    final iconName = SafeParse.toStringValue(json['iconName']).trim();
    final savedAddress = SafeParse.toStringValue(json['savedAddress']).trim();
    return SavedPlaceModel(
      label: label.isEmpty ? 'Saved Place' : label,
      iconName: iconName.isEmpty ? 'map_pin' : iconName,
      savedAddress: savedAddress.isEmpty ? null : savedAddress,
      latitude: SafeParse.toNullableDouble(json['latitude']),
      longitude: SafeParse.toNullableDouble(json['longitude']),
      isDefault: _parseBoolean(json['isDefault'] ?? json['is_default']),
    );
  }

  static String encodeList(List<SavedPlaceModel> places) {
    return jsonEncode(places.map((p) => p.toJson()).toList());
  }
}

bool _parseBoolean(Object? value) {
  return switch (value) {
    final bool booleanValue => booleanValue,
    final num numericValue => numericValue != 0,
    final String stringValue => switch (stringValue.trim().toLowerCase()) {
      'true' || '1' => true,
      _ => false,
    },
    _ => false,
  };
}
