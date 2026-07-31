// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../HeatmapCellModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HeatmapCell _$HeatmapCellFromJson(Map<String, dynamic> json) => HeatmapCell(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  intensity: (json['intensity'] as num).toDouble(),
);

Map<String, dynamic> _$HeatmapCellToJson(HeatmapCell instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'intensity': instance.intensity,
    };
