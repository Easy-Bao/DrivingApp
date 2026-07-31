// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../WaypointModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Waypoint _$WaypointFromJson(Map<String, dynamic> json) => Waypoint(
  id: json['id'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  name: json['name'] as String,
  isPickup: json['isPickup'] as bool,
  passengerId: json['passengerId'] as String,
);

Map<String, dynamic> _$WaypointToJson(Waypoint instance) => <String, dynamic>{
  'id': instance.id,
  'lat': instance.lat,
  'lng': instance.lng,
  'name': instance.name,
  'isPickup': instance.isPickup,
  'passengerId': instance.passengerId,
};
