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
    final {
      'status': rawStatus,
      'driver_id': rawDriverId,
      'driver_name': rawDriverName,
      'plate_number': rawVehiclePlate,
      'vehicle_type': rawVehicleType,
      'pickup_latitude': rawPickupLat,
      'pickup_longitude': rawPickupLng,
      'dropoff_latitude': rawDestinationLat,
      'dropoff_longitude': rawDestinationLng,
    } = _canonicalPayload(
      json,
    );

    return RideUpdate(
      status: RideStatus.fromString(
        SafeParse.toStringValue(rawStatus, 'requested'),
      ),
      driverId: _nullableString(rawDriverId),
      driverName: SafeParse.toStringValue(rawDriverName, 'Driver'),
      vehiclePlate: SafeParse.toStringValue(rawVehiclePlate, '—'),
      vehicleType: SafeParse.toStringValue(rawVehicleType, 'Bao Bao'),
      pickupLat: SafeParse.toNullableDouble(rawPickupLat),
      pickupLng: SafeParse.toNullableDouble(rawPickupLng),
      destinationLat: SafeParse.toNullableDouble(rawDestinationLat),
      destinationLng: SafeParse.toNullableDouble(rawDestinationLng),
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

Map<String, Object?> _canonicalPayload(Map<String, dynamic> json) => {
  'status': json['status'],
  'driver_id': json['driver_id'] ?? json['driverId'],
  'driver_name': json['driver_name'] ?? json['driverName'],
  'plate_number': json['plate_number'] ?? json['vehiclePlate'],
  'vehicle_type': json['vehicle_type'] ?? json['vehicleType'],
  'pickup_latitude': json['pickup_latitude'],
  'pickup_longitude': json['pickup_longitude'],
  'dropoff_latitude': json['dropoff_latitude'],
  'dropoff_longitude': json['dropoff_longitude'],
};

String? _nullableString(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}
