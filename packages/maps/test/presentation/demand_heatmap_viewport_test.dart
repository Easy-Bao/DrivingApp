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

  test(
    'clear invalidates in-flight tile loads from earlier generations',
    () async {
      var requestCount = 0;
      final coordinator = DemandHeatmapViewportCoordinator<String>(
        tileSizeDegrees: 1,
        loadTile: (bounds) async {
          final call = ++requestCount;
          await Future<void>.delayed(Duration.zero);
          return ['gen-$call'];
        },
      );
      const viewport = MapViewportBounds(
        minLatitude: 7.1,
        minLongitude: 123.1,
        maxLatitude: 7.9,
        maxLongitude: 123.9,
      );

      final staleRefresh = coordinator.refresh(viewport);
      coordinator.clear();
      final staleResult = await staleRefresh;
      expect(staleResult, isEmpty);

      final freshResult = await coordinator.refresh(viewport);
      expect(requestCount, 2);
      expect(freshResult, ['gen-2']);
    },
  );

  test(
    'evicts least-recently-used tiles when maxLoadedTiles is exceeded',
    () async {
      var requestCount = 0;
      final coordinator = DemandHeatmapViewportCoordinator<String>(
        tileSizeDegrees: 1,
        maxLoadedTiles: 2,
        loadTile: (bounds) async {
          requestCount++;
          return ['${bounds.minLatitude.toInt()}'];
        },
      );

      const tile1 = MapViewportBounds(
        minLatitude: 1.1,
        minLongitude: 1.1,
        maxLatitude: 1.2,
        maxLongitude: 1.2,
      );
      const tile2 = MapViewportBounds(
        minLatitude: 2.1,
        minLongitude: 1.1,
        maxLatitude: 2.2,
        maxLongitude: 1.2,
      );
      const tile3 = MapViewportBounds(
        minLatitude: 3.1,
        minLongitude: 1.1,
        maxLatitude: 3.2,
        maxLongitude: 1.2,
      );

      await coordinator.refresh(tile1);
      await coordinator.refresh(tile2);
      // Touch tile1 so tile2 becomes the least-recently-used entry.
      await coordinator.refresh(tile1);
      await coordinator.refresh(tile3);
      expect(requestCount, 3);

      // tile1 is still cached; tile2 was evicted and must reload.
      await coordinator.refresh(tile1);
      expect(requestCount, 3);
      await coordinator.refresh(tile2);
      expect(requestCount, 4);
    },
  );

  test(
    'caps tile requests on wide viewports and clamps negative bounds',
    () async {
      final requestedBounds = <MapViewportBounds>[];
      final coordinator = DemandHeatmapViewportCoordinator<String>(
        tileSizeDegrees: 0.05,
        maxTilesPerRefresh: 9,
        loadTile: (bounds) async {
          requestedBounds.add(bounds);
          return ['ok'];
        },
      );

      await coordinator.refresh(
        const MapViewportBounds(
          minLatitude: -90,
          minLongitude: -180,
          maxLatitude: 90,
          maxLongitude: 180,
        ),
      );
      expect(requestedBounds.length, lessThanOrEqualTo(9));

      requestedBounds.clear();
      await coordinator.refresh(
        const MapViewportBounds(
          minLatitude: -90,
          minLongitude: -180,
          maxLatitude: -89.99,
          maxLongitude: -179.99,
        ),
      );
      expect(requestedBounds, isNotEmpty);
      for (final bounds in requestedBounds) {
        expect(bounds.isValid, isTrue);
        expect(bounds.minLatitude, greaterThanOrEqualTo(-90));
        expect(bounds.minLongitude, greaterThanOrEqualTo(-180));
      }
    },
  );
}
