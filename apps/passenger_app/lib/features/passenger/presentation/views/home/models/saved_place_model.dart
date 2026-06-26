import 'dart:convert';
import 'package:flutter/material.dart';

/**
 * Domain model for a passenger-defined saved-place shortcut chip.
 *
 * A saved place represents a named location pinned by the passenger (e.g.
 * "Home", "Campus", "Gym") that appears on the passenger home screen as a
 * one-tap navigation shortcut. When coordinates are present, tapping the chip
 * routes directly to DestinationPreview, bypassing the search flow entirely.
 * When coordinates are absent the chip opens SearchDestination as a fallback.
 *
 * Instances are serialised to JSON and persisted in SharedPreferences under a
 * versioned list key. The [iconName] string is mapped back to an [IconData]
 * at the presentation layer to avoid storing platform-specific integers.
 *
 * Serialisation schema (JSON object):
 * - `label`        String  Display name of the saved place.
 * - `iconName`     String  Key matching AppIconMap for icon resolution.
 * - `savedAddress` String? Human-readable reverse-geocoded address.
 * - `latitude`     double? WGS84 latitude of the pinned location.
 * - `longitude`    double? WGS84 longitude of the pinned location.
 */
class SavedPlaceModel {
  final String label;
  final String iconName;
  final String? savedAddress;
  final double? latitude;
  final double? longitude;

  /** Callback injected by the presentation layer when building chip widgets. */
  final VoidCallback onTap;

  const SavedPlaceModel({
    required this.label,
    required this.iconName,
    required this.onTap,
    this.savedAddress,
    this.latitude,
    this.longitude,
  });

  /** Returns true when this saved place has persisted coordinates. */
  bool get hasLocation => latitude != null && longitude != null;

  SavedPlaceModel copyWith({
    String? label,
    String? iconName,
    String? savedAddress,
    double? latitude,
    double? longitude,
    VoidCallback? onTap,
  }) {
    return SavedPlaceModel(
      label: label ?? this.label,
      iconName: iconName ?? this.iconName,
      savedAddress: savedAddress ?? this.savedAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      onTap: onTap ?? this.onTap,
    );
  }

  /**
   * Serialises this model to a JSON-compatible map for storage.
   * The [onTap] callback is intentionally excluded from serialisation
   * since callbacks cannot be stored and are re-injected at deserialization.
   */
  Map<String, dynamic> toJson() => {
    'label': label,
    'iconName': iconName,
    if (savedAddress != null) 'savedAddress': savedAddress,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  /**
   * Deserialises a JSON map into a [SavedPlaceModel].
   * The [onTap] field is required separately since callbacks are not persisted.
   */
  factory SavedPlaceModel.fromJson(
    Map<String, dynamic> json,
    VoidCallback onTap,
  ) {
    return SavedPlaceModel(
      label: json['label'] as String,
      iconName: json['iconName'] as String,
      savedAddress: json['savedAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      onTap: onTap,
    );
  }

  /** Convenience factory for the three default shortcut seeds. */
  static List<Map<String, String>> get defaults => const [
    {'label': 'Home', 'iconName': 'house'},
    {'label': 'Campus', 'iconName': 'graduation_cap'},
    {'label': 'Work', 'iconName': 'briefcase'},
  ];

  static String encodeList(List<SavedPlaceModel> places) {
    return jsonEncode(places.map((p) => p.toJson()).toList());
  }
}
