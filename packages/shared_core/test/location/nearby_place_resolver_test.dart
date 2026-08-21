import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  const originLatitude = 7.0731;
  const originLongitude = 125.6128;

  test('calculates and retains a missing distance for nearby places', () {
    const place = PlaceModel(
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
    const nearby = PlaceModel(
      id: 'nearby',
      name: 'Nearby place',
      fullAddress: 'Nearby address',
      latitude: originLatitude,
      longitude: originLongitude,
      distanceKm: 2.4,
    );
    const outside = PlaceModel(
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
