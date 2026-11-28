import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  const originLatitude = 7.0731;
  const originLongitude = 125.6128;

  test('calculates and retains a missing distance for nearby places', () {
    const place = Place(
      id: 'place-1',
      name: 'Nearby place',
      fullAddress: 'Nearby address',
      latitude: originLatitude,
      longitude: originLongitude,
    );

    final results = NearbyPlaceResolver.withinRadius(
      places: const [place],
      latitude: originLatitude,
      longitude: originLongitude,
      radiusKm: 5,
    );

    expect(results, hasLength(1));
    expect(results.single.distanceKm, 0);
  });

  test('preserves server distance and excludes places outside the radius', () {
    const nearby = Place(
      id: 'nearby',
      name: 'Nearby place',
      fullAddress: 'Nearby address',
      latitude: originLatitude,
      longitude: originLongitude,
      distanceKm: 2.4,
    );
    const outside = Place(
      id: 'outside',
      name: 'Outside place',
      fullAddress: 'Outside address',
      latitude: originLatitude,
      longitude: originLongitude,
      distanceKm: 5.1,
    );

    final results = NearbyPlaceResolver.withinRadius(
      places: const [nearby, outside],
      latitude: originLatitude,
      longitude: originLongitude,
      radiusKm: 5,
    );

    expect(results, [nearby]);
    expect(results.single.distanceKm, 2.4);
  });

  test(
    'resolveNearby keeps primary-radius places when matches exist inside it',
    () {
      const nearby = Place(
        id: 'nearby',
        name: 'Nearby place',
        fullAddress: 'Nearby address',
        latitude: originLatitude,
        longitude: originLongitude,
        distanceKm: 2.4,
      );
      const regional = Place(
        id: 'regional',
        name: 'Regional place',
        fullAddress: 'Regional address',
        latitude: originLatitude,
        longitude: originLongitude,
        distanceKm: 11.2,
      );

      final results = NearbyPlaceResolver.resolveNearby(
        places: const [nearby, regional],
        latitude: originLatitude,
        longitude: originLongitude,
        primaryRadiusKm: 5,
        fallbackRadiusKm: 25,
      );

      expect(results, [nearby]);
    },
  );

  test('resolveNearby falls back to the wider radius when the primary radius is empty', () {
    const regional = Place(
      id: 'regional',
      name: 'Regional place',
      fullAddress: 'Regional address',
      latitude: originLatitude,
      longitude: originLongitude,
      distanceKm: 11.2,
    );
    const tooFar = Place(
      id: 'too-far',
      name: 'Far place',
      fullAddress: 'Far address',
      latitude: originLatitude,
      longitude: originLongitude,
      distanceKm: 30.0,
    );

    final results = NearbyPlaceResolver.resolveNearby(
      places: const [regional, tooFar],
      latitude: originLatitude,
      longitude: originLongitude,
      primaryRadiusKm: 5,
      fallbackRadiusKm: 25,
    );

    expect(results, [regional]);
  });
}
