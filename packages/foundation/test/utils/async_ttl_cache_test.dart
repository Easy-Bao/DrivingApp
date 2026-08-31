import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test(
    'shares in-flight work and reuses a successful value until expiry',
    () async {
      var now = DateTime(2026, 8, 28);
      var loadCount = 0;
      final cache = AsyncTtlCache<String, int>(
        ttl: const Duration(seconds: 10),
        maxEntries: 2,
        clock: () => now,
      );
      final response = Completer<int>();

      final first = cache.getOrLoad('route', () {
        loadCount++;
        return response.future;
      });
      final second = cache.getOrLoad('route', () {
        loadCount++;
        return Future.value(99);
      });

      expect(loadCount, 1);
      response.complete(42);
      expect(await Future.wait([first, second]), [42, 42]);

      expect(await cache.getOrLoad('route', () async => 99), 42);
      expect(loadCount, 1);

      now = now.add(const Duration(seconds: 10));
      expect(await cache.getOrLoad('route', () async => ++loadCount), 2);
      expect(loadCount, 2);
    },
  );

  test('does not retain values excluded by the cache policy', () async {
    var loadCount = 0;
    final cache = AsyncTtlCache<String, int?>(
      ttl: const Duration(seconds: 10),
      maxEntries: 2,
    );

    expect(
      await cache.getOrLoad('route', () async {
        loadCount++;
        return null;
      }, shouldCache: (value) => value != null),
      isNull,
    );
    expect(
      await cache.getOrLoad('route', () async {
        loadCount++;
        return null;
      }, shouldCache: (value) => value != null),
      isNull,
    );

    expect(loadCount, 2);
  });

  test('removes failed work so the next attempt can retry', () async {
    var loadCount = 0;
    final cache = AsyncTtlCache<String, int>(
      ttl: const Duration(seconds: 10),
      maxEntries: 2,
    );

    Future<int> load() async {
      loadCount++;
      if (loadCount == 1) throw StateError('temporary failure');
      return 7;
    }

    await expectLater(cache.getOrLoad('route', load), throwsStateError);
    expect(await cache.getOrLoad('route', load), 7);
    expect(loadCount, 2);
  });

  test('clears stale values without allowing an old request to repopulate', () async {
    final cache = AsyncTtlCache<String, int>(
      ttl: const Duration(minutes: 1),
      maxEntries: 2,
    );
    final response = Completer<int>();
    var loadCount = 0;

    final pending = cache.getOrLoad('route', () {
      loadCount++;
      return response.future;
    });
    cache.clear();
    response.complete(1);
    expect(await pending, 1);

    expect(await cache.getOrLoad('route', () async => ++loadCount), 2);
    expect(loadCount, 2);
  });
}
