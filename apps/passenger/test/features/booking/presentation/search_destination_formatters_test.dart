import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/search_destination_formatters.dart';

void main() {
  const mountainView = Place(
    id: 'mountain-view',
    name: 'Mountain View',
    fullAddress: 'Mountain View, California',
    latitude: 37.3861,
    longitude: -122.0839,
    distanceKm: 2.4,
  );
  const vistaSlope = Place(
    id: 'vista-slope',
    name: 'Vista Slope',
    fullAddress: 'Vista Slope, California',
    latitude: 37.4,
    longitude: -122.1,
    distanceKm: 1.2,
  );

  test('matches normalized and tokenized destination queries', () {
    expect(destinationMatchesSearchQuery(mountainView, 'mountainview'), isTrue);
    expect(destinationMatchesSearchQuery(mountainView, 'Mou Vie'), isTrue);
    expect(destinationMatchesSearchQuery(mountainView, 'bathroom'), isFalse);
  });

  test('sorts with driving distance before straight-line distance', () {
    final sorted = sortDestinationsByDistance(
      [mountainView, vistaSlope],
      {destinationPlaceKey(mountainView): 0.4},
    );

    expect(sorted, [mountainView, vistaSlope]);
  });

  test('merges destination names once after punctuation normalization', () {
    const renamedMountainView = Place(
      id: 'duplicate-name',
      name: 'Mountain-View!',
      fullAddress: 'Another address',
      latitude: 1,
      longitude: 2,
    );

    final merged = mergeUniqueDestinationResults(
      [mountainView],
      [renamedMountainView, vistaSlope],
    );

    expect(destinationNameKey(renamedMountainView), 'mountainview');
    expect(merged, [mountainView, vistaSlope]);
  });

  test('deduplicates nearby coordinates without dropping distinct places', () {
    const sameCoordinate = Place(
      id: 'same-coordinate',
      name: 'Different name',
      fullAddress: 'Nearby address',
      latitude: 37.38615,
      longitude: -122.08385,
    );
    const distinctCoordinate = Place(
      id: 'distinct-coordinate',
      name: 'Another name',
      fullAddress: 'Farther address',
      latitude: 37.38621,
      longitude: -122.0839,
    );

    final merged = mergeUniqueDestinationResults(
      [mountainView],
      [sameCoordinate, distinctCoordinate],
      compareCoordinates: true,
    );

    expect(merged, [mountainView, distinctCoordinate]);
  });

  test('formats pending, route, and nearby destination distances', () {
    expect(
      formatDestinationPlaceDistance(mountainView, const {}, {
        destinationPlaceKey(mountainView),
      }),
      'Calculating route...',
    );
    expect(
      formatDestinationPlaceDistance(mountainView, {
        destinationPlaceKey(mountainView): 0.05,
      }, const {}),
      '50 m away',
    );
    expect(
      formatDestinationPlaceDistance(vistaSlope, const {}, const {}),
      '1.2 km away',
    );
  });
}
