import 'dart:convert';

import 'package:driver/src/infrastructure/telemetry/driver_location_spool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('measures spool enqueue and flush at representative depths', (
    _,
  ) async {
    const storageKey = 'driver_location_spool_v1';
    const maximumPoints = 3600;
    final preferences = SharedPreferencesAsync();
    final spool = DriverLocationSpool(preferences: preferences);

    try {
      for (final depth in [0, 1000, maximumPoints]) {
        if (depth == 0) {
          await preferences.remove(storageKey);
        } else {
          await preferences.setString(storageKey, _encodedPoints(depth));
        }

        final stopwatch = Stopwatch()..start();
        await spool.enqueue(_point(maximumPoints));
        stopwatch.stop();

        final storedPoints = jsonDecode(
          (await preferences.getString(storageKey))!,
        ) as List<dynamic>;
        expect(
          storedPoints,
          hasLength(depth == maximumPoints ? maximumPoints : depth + 1),
        );
        print(
          'driver_location_spool.enqueue depth=$depth '
          'elapsed_us=${stopwatch.elapsedMicroseconds}',
        );
      }

      for (final depth in [50, 250, 500]) {
        await preferences.setString(storageKey, _encodedPoints(depth));

        final stopwatch = Stopwatch()..start();
        final flushed = await spool.flush((_) async => true);
        stopwatch.stop();

        expect(flushed, isTrue);
        expect(await preferences.getString(storageKey), isNull);
        print(
          'driver_location_spool.flush points=$depth '
          'elapsed_us=${stopwatch.elapsedMicroseconds}',
        );
      }
    } finally {
      await preferences.remove(storageKey);
    }
  });
}

String _encodedPoints(int count) {
  return jsonEncode(
    List.generate(
      count,
      _point,
    ).map((point) => point.toJson()).toList(growable: false),
  );
}

DriverLocationPoint _point(int index) {
  return DriverLocationPoint(
    latitude: 0,
    longitude: 0,
    observedAt: DateTime.utc(2026).add(Duration(seconds: index)),
    heading: 90,
    speed: 1,
  );
}
