import 'dart:convert';

import 'package:driver/src/core/telemetry/location_spool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('flushes queued coordinates oldest-first and removes them', () async {
    final spool = LocationSpool();
    final sent = <double>[];

    await spool.enqueue(_point(latitude: 7.1));
    await spool.enqueue(_point(latitude: 7.2));

    expect(
      await spool.flush((point) async {
        sent.add(point.latitude);
        return true;
      }),
      isTrue,
    );
    expect(sent, <double>[7.1, 7.2]);

    final retried = <double>[];
    expect(
      await spool.flush((point) async {
        retried.add(point.latitude);
        return true;
      }),
      isTrue,
    );
    expect(retried, isEmpty);
  });

  test(
    'clear discards queued coordinates so another driver cannot send them',
    () async {
      final spool = LocationSpool();
      await spool.enqueue(_point(latitude: 7.1));

      await spool.clear();

      final sent = <double>[];
      expect(
        await spool.flush((point) async {
          sent.add(point.latitude);
          return true;
        }),
        isTrue,
      );
      expect(sent, isEmpty);
    },
  );

  test('retains the failed point and later points for a retry', () async {
    final spool = LocationSpool();
    await spool.enqueue(_point(latitude: 7.1));
    await spool.enqueue(_point(latitude: 7.2));

    expect(await spool.flush((_) async => false), isFalse);

    final retried = <double>[];
    expect(
      await spool.flush((point) async {
        retried.add(point.latitude);
        return true;
      }),
      isTrue,
    );
    expect(retried, <double>[7.1, 7.2]);
  });

  test('persists an acknowledged prefix before a failed send', () async {
    final spool = LocationSpool();
    await spool.enqueue(_point(latitude: 7.1));
    await spool.enqueue(_point(latitude: 7.2));
    await spool.enqueue(_point(latitude: 7.3));
    var sendCount = 0;

    expect(await spool.flush((_) async => ++sendCount == 1), isFalse);

    final retried = <double>[];
    expect(
      await spool.flush((point) async {
        retried.add(point.latitude);
        return true;
      }),
      isTrue,
    );
    expect(retried, <double>[7.2, 7.3]);
  });

  test(
    'commits each bounded batch before progressing to later points',
    () async {
      final spool = LocationSpool();
      for (var latitude = 0; latitude < 11; latitude++) {
        await spool.enqueue(_point(latitude: latitude.toDouble()));
      }
      final sent = <double>[];

      expect(
        await spool.flush((point) async {
          if (sent.length == 10) return false;
          sent.add(point.latitude);
          return true;
        }),
        isFalse,
      );
      expect(sent, List<double>.generate(10, (index) => index.toDouble()));

      final retried = <double>[];
      expect(
        await spool.flush((point) async {
          retried.add(point.latitude);
          return true;
        }),
        isTrue,
      );
      expect(retried, <double>[10]);
    },
  );

  test(
    'skips corrupt stored entries without discarding valid spooled points',
    () async {
      final preferences = SharedPreferencesAsync();
      await preferences.setString(
        'driver_location_spool_v1',
        jsonEncode([
          _point(latitude: 7.1).toJson(),
          {'latitude': 'not-a-number', 'observed_at': 'bad-date'},
          'unexpected-primitive',
          _point(latitude: 7.3).toJson(),
        ]),
      );

      final spool = LocationSpool(preferences: preferences);
      final sent = <double>[];
      expect(
        await spool.flush((point) async {
          sent.add(point.latitude);
          return true;
        }),
        isTrue,
      );
      expect(sent, <double>[7.1, 7.3]);
    },
  );

  test(
    'drops permanent poison-pill points and continues flushing later points',
    () async {
      final spool = LocationSpool();
      await spool.enqueue(_point(latitude: 7.1));
      await spool.enqueue(_point(latitude: 7.2));
      final delivered = <double>[];

      final succeeded = await spool.flushWithOutcome((point) async {
        if (point.latitude == 7.1) return LocationSendOutcome.drop;
        delivered.add(point.latitude);
        return LocationSendOutcome.sent;
      });

      expect(succeeded, isTrue);
      expect(delivered, <double>[7.2]);
    },
  );
}

LocationPoint _point({required double latitude}) {
  return LocationPoint(
    latitude: latitude,
    longitude: 123.4,
    observedAt: DateTime.utc(2026, 9, 18),
  );
}
