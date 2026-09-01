import 'dart:math' as math;

import 'package:maps/src/domain/entities/place.dart';

/// Resolves nearby places using server-provided distances when available.
///
/// Map providers may omit `distance_km` for valid results. Keeping the
/// fallback here makes both clients apply the same radius and distance rules.
class NearbyPlaceResolver._() {
  static List<Place> withinRadius({
    required List<Place> places,
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    if (!radiusKm.isFinite || radiusKm < 0) return const [];

    return places
        .map((place) {
          final distanceKm =
              place.distanceKm ??
              _haversineKm(
                latitude,
                longitude,
                place.latitude,
                place.longitude,
              );
          if (!distanceKm.isFinite || distanceKm < 0 || distanceKm > radiusKm) {
            return null;
          }
          return place.distanceKm == null
              ? place.copyWith(distanceKm: distanceKm)
              : place;
        })
        .whereType<Place>()
        .toList(growable: false);
  }

  static double _haversineKm(
    double latitude,
    double longitude,
    double otherLatitude,
    double otherLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    final latitudeDelta = _toRadians(otherLatitude - latitude);
    final longitudeDelta = _toRadians(otherLongitude - longitude);
    final originLatitude = _toRadians(latitude);
    final destinationLatitude = _toRadians(otherLatitude);

    final rawA =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(originLatitude) *
            math.cos(destinationLatitude) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    final a = rawA.clamp(0.0, 1.0).toDouble();
    return earthRadiusKm * 2 * math.asin(math.sqrt(a));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
