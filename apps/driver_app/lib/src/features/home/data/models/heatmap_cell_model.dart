import 'package:equatable/equatable.dart';

class HeatmapCell extends Equatable {
  final double lat;
  final double lng;
  final double intensity;

  const HeatmapCell({
    required this.lat,
    required this.lng,
    required this.intensity,
  });

  factory HeatmapCell.fromJson(Map<String, dynamic> json) {
    return HeatmapCell(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng, 'intensity': intensity};
  }

  @override
  List<Object?> get props => [lat, lng, intensity];
}
