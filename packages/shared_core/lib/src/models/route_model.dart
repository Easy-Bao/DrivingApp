import 'package:equatable/equatable.dart';

enum RoutePreference { fastest, shortest }

enum RouteProfile { driving, drivingTraffic }

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

class RouteModel extends Equatable {
  final List<List<double>> polylinePoints;
  final double distanceKm;
  final int durationSeconds;
  final String summary;
  final String preference;
  final String profile;

  const RouteModel({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationSeconds,
    this.summary = '',
    this.preference = 'fastest',
    this.profile = 'driving',
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final rawPoints =
        (json['polylinePoints'] as List<dynamic>?) ??
        (json['polyline'] as List<dynamic>?) ??
        (json['waypoints'] as List<dynamic>?) ??
        <dynamic>[];
    final points = rawPoints
        .whereType<List<dynamic>>()
        .where((point) => point.length >= 2)
        .map(
          (point) => [
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          ],
        )
        .toList();

    final durationSeconds =
        json['durationSeconds'] as num? ?? json['duration_seconds'] as num?;
    final durationMinutes =
        json['durationMin'] as num? ?? json['duration_min'] as num?;

    return RouteModel(
      polylinePoints: points,
      distanceKm:
          (json['distanceKm'] as num? ?? json['distance_km'] as num? ?? 0.0)
              .toDouble(),
      durationSeconds:
          durationSeconds?.toInt() ?? ((durationMinutes ?? 0) * 60).round(),
      summary: json['summary'] as String? ?? '',
      preference: json['preference'] as String? ?? 'fastest',
      profile: json['profile'] as String? ?? 'driving',
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

extension RouteModelExtension on RouteModel {
  Duration get estimatedTime => Duration(seconds: durationSeconds);

  /// Returns only finite GeoJSON coordinates that Mapbox can render.
  /// Mapbox coordinates are ordered longitude first.
  List<List<double>> get validPolylinePoints => polylinePoints
      .where(_isValidPolylinePoint)
      .map((point) => [point[0], point[1]])
      .toList(growable: false);

  bool get hasGeometry => validPolylinePoints.length >= 2;

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

class RouteModelLegacyAdapter {
  RouteModelLegacyAdapter._();

  static RouteModel create({
    required List<List<double>> polylinePoints,
    required double distanceKm,
    required Duration estimatedTime,
    String summary = '',
  }) {
    return RouteModel(
      polylinePoints: polylinePoints,
      distanceKm: distanceKm,
      durationSeconds: estimatedTime.inSeconds,
      summary: summary,
    );
  }
}
