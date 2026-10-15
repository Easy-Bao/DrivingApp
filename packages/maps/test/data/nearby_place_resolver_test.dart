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
}
