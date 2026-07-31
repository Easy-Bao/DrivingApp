import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Generated/RouteModel.g.dart';

@JsonSerializable()
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

  factory RouteModel.fromJson(Map<String, dynamic> json) =>
      _$RouteModelFromJson(_normalizeRouteJson(json));

  Map<String, dynamic> toJson() => _$RouteModelToJson(this);

  @override
  List<Object?> get props => [
    polylinePoints,
    distanceKm,
    durationSeconds,
    summary,
  ];
}

Map<String, dynamic> _normalizeRouteJson(Map<String, dynamic> json) {
  final rawWaypoints = json['waypoints'] as List<dynamic>?;
  final polylinePoints =
      json['polylinePoints'] ??
      rawWaypoints?.map((rawPoint) {
        final point = rawPoint as List<dynamic>;
        return [point[1], point[0]];
      }).toList();
  final durationMin = json['durationMin'] as num?;

  return {
    ...json,
    'polylinePoints': polylinePoints,
    'distanceKm': json['distanceKm'] ?? json['distance_km'],
    'durationSeconds':
        json['durationSeconds'] ??
        (durationMin == null ? null : (durationMin.toDouble() * 60).round()),
  };
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
