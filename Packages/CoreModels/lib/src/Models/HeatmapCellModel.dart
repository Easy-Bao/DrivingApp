import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Generated/HeatmapCellModel.g.dart';

@JsonSerializable()
class HeatmapCell extends Equatable {
  final double lat;
  final double lng;
  final double intensity;

  const HeatmapCell({
    required this.lat,
    required this.lng,
    required this.intensity,
  });

  factory HeatmapCell.fromJson(Map<String, dynamic> json) =>
      _$HeatmapCellFromJson(json);

  Map<String, dynamic> toJson() => _$HeatmapCellToJson(this);

  @override
  List<Object?> get props => [lat, lng, intensity];
}

