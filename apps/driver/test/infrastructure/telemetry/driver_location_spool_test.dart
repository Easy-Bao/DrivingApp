import 'package:driver/src/infrastructure/telemetry/driver_location_spool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('flushes queued coordinates oldest-first and removes them', () async {
    final spool = DriverLocationSpool();
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

  test('retains the failed point and later points for a retry', () async {
    final spool = DriverLocationSpool();
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
    final spool = DriverLocationSpool();
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
      final spool = DriverLocationSpool();
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
}

DriverLocationPoint _point({required double latitude}) {
  return DriverLocationPoint(
    latitude: latitude,
    longitude: 123.4,
    observedAt: DateTime.utc(2026, 9, 18),
  );
}
