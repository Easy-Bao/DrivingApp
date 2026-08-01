import 'package:equatable/equatable.dart';
import 'RideStatusModel.dart';

class RideUpdate extends Equatable {
  final RideStatus status;
  final String? driverId;
  final String driverName;
  final String vehiclePlate;
  final String vehicleType;

  const RideUpdate({
    required this.status,
    this.driverId,
    this.driverName = 'Driver',
    this.vehiclePlate = '—',
    this.vehicleType = 'Bao Bao',
  });

  factory RideUpdate.fromJson(Map<String, dynamic> json) {
    return RideUpdate(
      status: RideStatus.fromString(json['status'] as String? ?? 'requested'),
      driverId: json['driver_id'] as String? ?? json['driverId'] as String?,
      driverName: json['driver_name'] as String? ?? json['driverName'] as String? ?? 'Driver',
      vehiclePlate: json['plate_number'] as String? ?? json['vehiclePlate'] as String? ?? '—',
      vehicleType: json['vehicle_type'] as String? ?? json['vehicleType'] as String? ?? 'Bao Bao',
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
      ];
}
