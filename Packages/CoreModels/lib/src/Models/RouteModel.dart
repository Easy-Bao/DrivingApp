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
    final rawPoints = json['polylinePoints'] as List<dynamic>? ?? [];
    final points = rawPoints.map((item) {
      final list = item as List<dynamic>;
      return [ (list[0] as num).toDouble(), (list[1] as num).toDouble() ];
    }).toList();

    return RouteModel(
      polylinePoints: points,
      distanceKm: (json['distanceKm'] as num? ?? json['distance_km'] as num? ?? 0.0).toDouble(),
      durationSeconds: json['durationSeconds'] as int? ?? json['duration_seconds'] as int? ?? 0,
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
