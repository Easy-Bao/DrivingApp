import 'dart:convert';

import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.observedAt,
    this.heading,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final DateTime observedAt;
  final double? heading;
  final double? speed;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'observed_at': observedAt.toUtc().toIso8601String(),
    'heading': heading,
    'speed': speed,
  };

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      observedAt: DateTime.parse(json['observed_at'] as String).toUtc(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }
}

enum LocationSendOutcome { sent, drop, retry }

typedef LocationSender = Future<bool> Function(LocationPoint point);
typedef LocationOutcomeSender = Future<LocationSendOutcome> Function(
  LocationPoint point,
);

final class LocationSpool {
  static const _storageKey = 'driver_location_spool_v1';
  static const _maximumPoints = 3600;
  static const _flushCommitBatchSize = 10;

  LocationSpool({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  Future<void> _operation = Future<void>.value();

  Future<void> enqueue(LocationPoint point) {
    return _serialize(
      () => traceTimelineStage('driver.location_spool.enqueue', () async {
        final points = await _read();
        points.add(point);
        if (points.length > _maximumPoints) {
          points.removeRange(0, points.length - _maximumPoints);
        }
        await _write(points);
      }),
    );
  }

  Future<void> clear() {
    return _serialize(() => _preferences.remove(_storageKey));
  }

  Future<bool> flush(LocationSender send) {
    return flushWithOutcome((point) async {
      return await send(point)
          ? LocationSendOutcome.sent
          : LocationSendOutcome.retry;
    });
  }

  Future<bool> flushWithOutcome(LocationOutcomeSender send) {
    return _serialize(
      () => traceTimelineStage('driver.location_spool.flush', () async {
        final points = await _read();
        while (points.isNotEmpty) {
          var consumedCount = 0;
          while (consumedCount < _flushCommitBatchSize &&
              consumedCount < points.length) {
            final outcome = await send(points[consumedCount]);
            if (outcome == LocationSendOutcome.retry) {
              if (consumedCount > 0) {
                points.removeRange(0, consumedCount);
                await _write(points);
              }
              return false;
            }
            consumedCount++;
          }

          // A process restart may replay one acknowledged batch; the server
          // treats already-seen timestamps as successful stale-point no-ops.
          points.removeRange(0, consumedCount);
          await _write(points);
        }
        return true;
      }),
    );
  }

  Future<List<LocationPoint>> _read() async {
    final encoded = await _preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return <LocationPoint>[];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        await _preferences.remove(_storageKey);
        return <LocationPoint>[];
      }
      final validPoints = <LocationPoint>[];
      var skippedCorruptEntry = false;
      for (final item in decoded) {
        if (item is! Map) {
          skippedCorruptEntry = true;
          continue;
        }
        try {
          validPoints.add(
            LocationPoint.fromJson(Map<String, dynamic>.from(item)),
          );
        } on FormatException {
          skippedCorruptEntry = true;
        } on TypeError {
          skippedCorruptEntry = true;
        }
      }
      if (skippedCorruptEntry) {
        await _write(validPoints);
      }
      return validPoints;
    } on FormatException {
      await _preferences.remove(_storageKey);
      return <LocationPoint>[];
    } on TypeError {
      await _preferences.remove(_storageKey);
      return <LocationPoint>[];
    }
  }

  Future<void> _write(List<LocationPoint> points) async {
    if (points.isEmpty) {
      await _preferences.remove(_storageKey);
      return;
    }
    await _preferences.setString(
      _storageKey,
      jsonEncode(points.map((point) => point.toJson()).toList()),
    );
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final next = _operation.then((_) => action());
    _operation = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }
}
