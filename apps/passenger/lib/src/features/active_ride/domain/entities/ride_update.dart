import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

import 'package:passenger/src/features/active_ride/domain/entities/ride_status.dart';

final class const RideUpdate({
  required final RideStatus status,
  final String? driverId,
  final String driverName = 'Driver',
  final String vehiclePlate = '—',
  final String vehicleType = 'Bao Bao',
  final double? pickupLat,
  final double? pickupLng,
  final double? destinationLat,
  final double? destinationLng,
}) extends Equatable {
  factory fromJson(Map<String, dynamic> json) {
    return RideUpdate(
      status: RideStatus.fromString(
        SafeParse.toStringValue(json['status'], 'requested'),
      ),
      driverId: _nullableString(json['driver_id'] ?? json['driverId']),
      driverName: SafeParse.toStringValue(
        json['driver_name'] ?? json['driverName'],
        'Driver',
      ),
      vehiclePlate: SafeParse.toStringValue(
        json['plate_number'] ?? json['vehiclePlate'],
        '—',
      ),
      vehicleType: SafeParse.toStringValue(
        json['vehicle_type'] ?? json['vehicleType'],
        'Bao Bao',
      ),
      pickupLat: SafeParse.toNullableDouble(json['pickup_latitude']),
      pickupLng: SafeParse.toNullableDouble(json['pickup_longitude']),
      destinationLat: SafeParse.toNullableDouble(json['dropoff_latitude']),
      destinationLng: SafeParse.toNullableDouble(json['dropoff_longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'driver_id': driverId,
      'driver_name': driverName,
      'plate_number': vehiclePlate,
      'vehicle_type': vehicleType,
    };
  }

  @override
  List<Object?> get props => [
    status,
    driverId,
    driverName,
    vehiclePlate,
    vehicleType,
    pickupLat,
    pickupLng,
    destinationLat,
    destinationLng,
  ];
}

String? _nullableString(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}
