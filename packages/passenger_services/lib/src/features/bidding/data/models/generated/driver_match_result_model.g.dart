// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../driver_match_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverMatchResultModel _$DriverMatchResultModelFromJson(
  Map<String, dynamic> json,
) => _DriverMatchResultModel(
  trip: BidSessionTripModel.fromJson(json['trip'] as Map<String, dynamic>),
  driverId: json['driverId'] as String,
  driverName: json['driverName'] as String,
  fare: (json['fare'] as num).toDouble(),
  driverRating: json['driverRating'] as String?,
  vehicleType: json['vehicleType'] as String,
  plateNumber: json['plateNumber'] as String,
);

Map<String, dynamic> _$DriverMatchResultModelToJson(
  _DriverMatchResultModel instance,
) => <String, dynamic>{
  'trip': instance.trip,
  'driverId': instance.driverId,
  'driverName': instance.driverName,
  'fare': instance.fare,
  'driverRating': instance.driverRating,
  'vehicleType': instance.vehicleType,
  'plateNumber': instance.plateNumber,
};
