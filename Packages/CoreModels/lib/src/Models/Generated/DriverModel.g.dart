// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../DriverModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverModel _$DriverModelFromJson(Map<String, dynamic> json) => DriverModel(
  id: json['id'] as String,
  name: json['name'] as String,
  vehicleType: json['vehicleType'] as String,
  plateNumber: json['plateNumber'] as String,
  rating: (json['rating'] as num).toDouble(),
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  distanceKm: (json['distanceKm'] as num).toDouble(),
  etaMinutes: (json['etaMinutes'] as num).toDouble(),
  score: (json['score'] as num).toDouble(),
  hasPassengerOnboard: json['hasPassengerOnboard'] as bool? ?? false,
  avatarUrl: json['avatarUrl'] as String?,
  recentFeedback: json['recentFeedback'] as String?,
);

Map<String, dynamic> _$DriverModelToJson(DriverModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'vehicleType': instance.vehicleType,
      'plateNumber': instance.plateNumber,
      'rating': instance.rating,
      'lat': instance.lat,
      'lng': instance.lng,
      'distanceKm': instance.distanceKm,
      'etaMinutes': instance.etaMinutes,
      'score': instance.score,
      'hasPassengerOnboard': instance.hasPassengerOnboard,
      'avatarUrl': instance.avatarUrl,
      'recentFeedback': instance.recentFeedback,
    };
