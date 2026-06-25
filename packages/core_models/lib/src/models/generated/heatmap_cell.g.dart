// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../heatmap_cell.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HeatmapCell _$HeatmapCellFromJson(Map<String, dynamic> json) => _HeatmapCell(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  intensity: (json['intensity'] as num).toDouble(),
);

Map<String, dynamic> _$HeatmapCellToJson(_HeatmapCell instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'intensity': instance.intensity,
    };
