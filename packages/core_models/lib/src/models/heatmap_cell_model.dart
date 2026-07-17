import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/heatmap_cell_model.freezed.dart';
part 'generated/heatmap_cell_model.g.dart';

@freezed
abstract class HeatmapCell with _$HeatmapCell {
  const factory HeatmapCell({
    required double lat,
    required double lng,
    required double intensity,
  }) = _HeatmapCell;

  factory HeatmapCell.fromJson(Map<String, dynamic> json) =>
      _$HeatmapCellFromJson(json);
}
