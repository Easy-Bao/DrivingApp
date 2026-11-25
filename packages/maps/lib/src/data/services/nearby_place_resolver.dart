import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/geo_math.dart';

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
              GeoMath.haversineKm(
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
}
