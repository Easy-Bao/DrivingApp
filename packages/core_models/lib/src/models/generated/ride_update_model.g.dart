// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../ride_update_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RideUpdate _$RideUpdateFromJson(Map<String, dynamic> json) => _RideUpdate(
  status: RideStatus.fromString(json['status'] as String),
  driverId: json['driver_id'] as String?,
  driverName: json['driver_name'] as String? ?? 'Driver',
  vehiclePlate: json['plate_number'] as String? ?? '—',
  vehicleType: json['vehicle_type'] as String? ?? 'Bao Bao',
);

Map<String, dynamic> _$RideUpdateToJson(_RideUpdate instance) =>
    <String, dynamic>{
      'status': _$RideStatusEnumMap[instance.status]!,
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'plate_number': instance.vehiclePlate,
      'vehicle_type': instance.vehicleType,
    };

const _$RideStatusEnumMap = {
  RideStatus.requested: 'requested',
  RideStatus.accepted: 'accepted',
  RideStatus.arrived: 'arrived',
  RideStatus.inTransit: 'inTransit',
  RideStatus.completed: 'completed',
  RideStatus.cancelled: 'cancelled',
  RideStatus.unknown: 'unknown',
};
