// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../auth_credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthCredentials _$AuthCredentialsFromJson(Map<String, dynamic> json) =>
    _AuthCredentials(
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      driverEmail: json['driverEmail'] as String,
      vehicleType: json['vehicleType'] as String,
      plateNumber: json['plateNumber'] as String,
      rating: (json['rating'] as num).toDouble(),
    );

Map<String, dynamic> _$AuthCredentialsToJson(_AuthCredentials instance) =>
    <String, dynamic>{
      'driverId': instance.driverId,
      'driverName': instance.driverName,
      'driverEmail': instance.driverEmail,
      'vehicleType': instance.vehicleType,
      'plateNumber': instance.plateNumber,
      'rating': instance.rating,
    };
