import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  test('loads a newly visible zone after the map moves into it', () async {
    final requestedBounds = <MapViewportBounds>[];
    final coordinator = DemandHeatmapViewportCoordinator<String>(
      tileSizeDegrees: 1,
      loadTile: (bounds) async {
        requestedBounds.add(bounds);
        return ['${bounds.minLatitude}:${bounds.minLongitude}'];
      },
    );

    final first = await coordinator.refresh(
      const MapViewportBounds(
        minLatitude: 7.1,
        minLongitude: 123.1,
        maxLatitude: 7.9,
        maxLongitude: 123.9,
      ),
    );
    final second = await coordinator.refresh(
      const MapViewportBounds(
        minLatitude: 8.1,
        minLongitude: 123.1,
        maxLatitude: 8.9,
        maxLongitude: 123.9,
      ),
    );

    expect(requestedBounds, hasLength(2));
    expect(first, ['7.0:123.0']);
    expect(second, ['8.0:123.0']);
  });

  test('deduplicates concurrent requests for the same zone', () async {
    var requestCount = 0;
    final coordinator = DemandHeatmapViewportCoordinator<int>(
      tileSizeDegrees: 1,
      loadTile: (bounds) async {
        requestCount++;
        await Future<void>.delayed(Duration.zero);
        return [bounds.minLatitude.toInt()];
      },
    );
    const viewport = MapViewportBounds(
      minLatitude: 7.1,
      minLongitude: 123.1,
      maxLatitude: 7.9,
      maxLongitude: 123.9,
    );

    final results = await Future.wait([
      coordinator.refresh(viewport),
      coordinator.refresh(viewport),
    ]);

    expect(requestCount, 1);
    expect(results[0], [7]);
    expect(results[1], [7]);
  });
}
