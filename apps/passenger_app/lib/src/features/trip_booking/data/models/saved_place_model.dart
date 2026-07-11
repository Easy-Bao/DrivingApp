import 'dart:convert';
import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';

/**
 * Data layer model for a passenger-defined saved-place shortcut.
 * Extends the domain entity [SavedPlace] to implement JSON serialization.
 */
class SavedPlaceModel extends SavedPlace {
  const SavedPlaceModel({
    required super.label,
    required super.iconName,
    super.savedAddress,
    super.latitude,
    super.longitude,
  });

  /** Mappings for default seed records on initial boot. */
  static List<Map<String, String>> get defaults => const [
    {'label': 'Home', 'iconName': 'house'},
    {'label': 'Campus', 'iconName': 'graduation_cap'},
    {'label': 'Work', 'iconName': 'briefcase'},
  ];

  /** Serialises this model to a JSON map. */
  Map<String, dynamic> toJson() => {
    'label': label,
    'iconName': iconName,
    if (savedAddress != null) 'savedAddress': savedAddress,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  /** Deserialises a JSON map into a [SavedPlaceModel]. */
  factory SavedPlaceModel.fromJson(Map<String, dynamic> json) {
    return SavedPlaceModel(
      label: json['label'] as String,
      iconName: json['iconName'] as String,
      savedAddress: json['savedAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  /** Helper method to encode a list of places to a JSON string. */
  static String encodeList(List<SavedPlaceModel> places) {
    return jsonEncode(places.map((p) => p.toJson()).toList());
  }
}
