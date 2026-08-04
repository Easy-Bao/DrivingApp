import 'package:equatable/equatable.dart';

class RouteModel extends Equatable {
  final List<List<double>> polylinePoints;
  final double distanceKm;
  final int durationSeconds;
  final String summary;

  const RouteModel({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationSeconds,
    this.summary = '',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'polylinePoints': polylinePoints,
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'summary': summary,
    };
  }

  @override
  List<Object?> get props => [
    polylinePoints,
    distanceKm,
    durationSeconds,
    summary,
  ];
}

extension RouteModelExtension on RouteModel {
  Duration get estimatedTime => Duration(seconds: durationSeconds);
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
