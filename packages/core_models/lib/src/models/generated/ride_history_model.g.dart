// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../ride_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RideHistoryModel _$RideHistoryModelFromJson(Map<String, dynamic> json) =>
    _RideHistoryModel(
      id: json['id'] as String,
      pickup: json['pickup'] as String,
      destination: json['destination'] as String,
      pickupLat: (json['pickupLat'] as num).toDouble(),
      pickupLng: (json['pickupLng'] as num).toDouble(),
      destLat: (json['destLat'] as num).toDouble(),
      destLng: (json['destLng'] as num).toDouble(),
      date: json['date'] as String,
      price: json['price'] as String,
      status: json['status'] as String,
      driverName: json['driverName'] as String? ?? '',
      vehiclePlate: json['vehiclePlate'] as String? ?? '',
    );

Map<String, dynamic> _$RideHistoryModelToJson(_RideHistoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pickup': instance.pickup,
      'destination': instance.destination,
      'pickupLat': instance.pickupLat,
      'pickupLng': instance.pickupLng,
      'destLat': instance.destLat,
      'destLng': instance.destLng,
      'date': instance.date,
      'price': instance.price,
      'status': instance.status,
      'driverName': instance.driverName,
      'vehiclePlate': instance.vehiclePlate,
    };
