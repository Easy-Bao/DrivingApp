import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class DriverLocationPoint {
  const DriverLocationPoint({
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

  factory DriverLocationPoint.fromJson(Map<String, dynamic> json) {
    return DriverLocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      observedAt: DateTime.parse(json['observed_at'] as String).toUtc(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }
}

typedef DriverLocationSender = Future<bool> Function(DriverLocationPoint point);

final class DriverLocationSpool {
  static const _storageKey = 'driver_location_spool_v1';
  static const _maximumPoints = 3600;

  DriverLocationSpool({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  Future<void> _operation = Future<void>.value();

  Future<void> enqueue(DriverLocationPoint point) {
    return _serialize(() async {
      final points = await _read();
      points.add(point);
      if (points.length > _maximumPoints) {
        points.removeRange(0, points.length - _maximumPoints);
      }
      await _write(points);
    });
  }

  Future<bool> flush(DriverLocationSender send) {
    return _serialize(() async {
      final points = await _read();
      while (points.isNotEmpty) {
        if (!await send(points.first)) return false;
        points.removeAt(0);
        await _write(points);
      }
      return true;
    });
  }

  Future<List<DriverLocationPoint>> _read() async {
    final encoded = await _preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return <DriverLocationPoint>[];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return <DriverLocationPoint>[];
      return decoded
          .whereType<Map>()
          .map(
            (value) =>
                DriverLocationPoint.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: true);
    } on FormatException {
      await _preferences.remove(_storageKey);
      return <DriverLocationPoint>[];
    } on TypeError {
      await _preferences.remove(_storageKey);
      return <DriverLocationPoint>[];
    }
  }

  Future<void> _write(List<DriverLocationPoint> points) async {
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
