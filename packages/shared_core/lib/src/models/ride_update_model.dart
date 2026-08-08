import 'package:equatable/equatable.dart';
import 'package:shared_core/src/enums/ride_status.dart';

class RideUpdate extends Equatable {
  final RideStatus status;
  final String? driverId;
  final String driverName;
  final String vehiclePlate;
  final String vehicleType;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;

  const RideUpdate({
    required this.status,
    this.driverId,
    this.driverName = 'Driver',
    this.vehiclePlate = '—',
    this.vehicleType = 'Bao Bao',
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  factory RideUpdate.fromJson(Map<String, dynamic> json) {
    return RideUpdate(
      status: RideStatus.fromString(json['status'] as String? ?? 'requested'),
      driverId: (json['driver_id'] ?? json['driverId'])?.toString(),
      driverName:
          json['driver_name'] as String? ??
          json['driverName'] as String? ??
          'Driver',
      vehiclePlate:
          json['plate_number'] as String? ??
          json['vehiclePlate'] as String? ??
          '—',
      vehicleType:
          json['vehicle_type'] as String? ??
          json['vehicleType'] as String? ??
          'Bao Bao',
      pickupLat: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLng: (json['pickup_longitude'] as num?)?.toDouble(),
      destinationLat: (json['dropoff_latitude'] as num?)?.toDouble(),
      destinationLng: (json['dropoff_longitude'] as num?)?.toDouble(),
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
