import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:foundation/foundation.dart';

enum RoutePreference { fastest, shortest }

enum RouteProfile { driving, drivingTraffic }

final Expando<Float64List> _routeCoordinateBuffers = Expando<Float64List>();

extension RoutePreferenceApi on RoutePreference {
  String get apiValue => switch (this) {
    RoutePreference.fastest => 'fastest',
    RoutePreference.shortest => 'shortest',
  };
}

extension RouteProfileApi on RouteProfile {
  String get apiValue => switch (this) {
    RouteProfile.driving => 'driving',
    RouteProfile.drivingTraffic => 'driving-traffic',
  };
}

class const Route({
  required this.polylinePoints,
  required this.distanceKm,
  required this.durationSeconds,
  this.summary = '',
  this.preference = 'fastest',
  this.profile = 'driving',
}) extends Equatable {
  final List<List<double>> polylinePoints;
  final double distanceKm;
  final int durationSeconds;
  final String summary;
  final String preference;
  final String profile;

  /// Interleaved, map-ready coordinates in GeoJSON order: longitude,
  /// latitude, longitude, latitude. The read-only buffer is weakly cached
  /// because this entity intentionally retains its const constructor.
  Float64List get coordinateBuffer {
    final cached = _routeCoordinateBuffers[this];
    if (cached != null) return cached;
    final buffer = _buildCoordinateBuffer(polylinePoints).asUnmodifiableView();
    _routeCoordinateBuffers[this] = buffer;
    return buffer;
  }

  factory fromJson(Map<String, dynamic> json) {
    final rawPoints = _readPointCollection(json);
    final points = rawPoints.map(_readPoint).whereType<List<double>>().toList();

    final durationSeconds = SafeParse.toNullableDouble(
      json['durationSeconds'] ?? json['duration_seconds'],
    );
    final durationMinutes = SafeParse.toNullableDouble(
      json['durationMin'] ?? json['duration_min'],
    );

    return Route(
      polylinePoints: points,
      distanceKm: SafeParse.toDouble(json['distanceKm'] ?? json['distance_km']),
      durationSeconds:
          durationSeconds?.toInt() ?? ((durationMinutes ?? 0) * 60).round(),
      summary: _readString(json['summary']),
      preference: _readString(json['preference'], 'fastest'),
      profile: _readString(json['profile'], 'driving'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'polylinePoints': polylinePoints,
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'summary': summary,
      'preference': preference,
      'profile': profile,
    };
  }

  @override
  List<Object?> get props => [
    polylinePoints,
    distanceKm,
    durationSeconds,
    summary,
    preference,
    profile,
  ];
}

List<Object?> _readPointCollection(Map<String, dynamic> json) {
  for (final key in ['polylinePoints', 'polyline', 'waypoints']) {
    final value = json[key];
    if (value is List) return List<Object?>.from(value);
  }
  return const [];
}

List<double>? _readPoint(Object? rawPoint) {
  if (rawPoint is! List || rawPoint.length < 2) return null;
  final longitude = SafeParse.toNullableDouble(rawPoint[0]);
  final latitude = SafeParse.toNullableDouble(rawPoint[1]);
  if (longitude == null || latitude == null) return null;
  return [longitude, latitude];
}

String _readString(Object? value, [String fallback = '']) {
  return value is String ? value : fallback;
}

extension RouteExtension on Route {
  /// Returns only finite GeoJSON coordinates that Mapbox can render.
  /// Mapbox coordinates are ordered longitude first.
  List<List<double>> get validPolylinePoints => polylinePoints
      .where(_isValidPolylinePoint)
      .map((point) => [point[0], point[1]])
      .toList(growable: false);

  bool get hasGeometry => validPolylinePoints.length >= 2;

  /// Returns the first valid point from the cached coordinate representation.
  /// Mapbox coordinates are ordered longitude first.
  ({double lat, double lng})? get bufferedStartCoordinate {
    final buffer = coordinateBuffer;
    if (buffer.length < 2) return null;
    return (lat: buffer[1], lng: buffer[0]);
  }

  /// Returns the first valid point from the GeoJSON polyline as a map-ready
  /// latitude/longitude pair. Mapbox coordinates are ordered longitude first.
  ({double lat, double lng})? get startCoordinate {
    final point = validPolylinePoints.firstOrNull;
    if (point != null) return (lat: point[1], lng: point[0]);
    return null;
  }
}

bool _isValidPolylinePoint(List<double> point) {
  return point.length >= 2 &&
      point[0].isFinite &&
      point[1].isFinite &&
      point[1] >= -90 &&
      point[1] <= 90 &&
      point[0] >= -180 &&
      point[0] <= 180;
}

Float64List _buildCoordinateBuffer(List<List<double>> points) {
  final buffer = Float64List(points.length * 2);
  var offset = 0;
  for (final point in points) {
    if (!_isValidPolylinePoint(point)) continue;
    buffer[offset++] = point[0];
    buffer[offset++] = point[1];
  }
  return offset == buffer.length ? buffer : buffer.sublist(0, offset);
}
