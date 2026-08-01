import 'package:equatable/equatable.dart';

class RideHistoryModel extends Equatable {
  final String id;
  final String pickup;
  final String destination;
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;
  final String date;
  final String price;
  final String status;
  final String driverId;
  final String driverName;
  final String vehiclePlate;
  final String vehicleType;

  const RideHistoryModel({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
    required this.date,
    required this.price,
    required this.status,
    required this.driverId,
    required this.driverName,
    required this.vehiclePlate,
    required this.vehicleType,
  });

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) {
    return RideHistoryModel(
      id: json['id'] as String? ?? '',
      pickup: json['pickup'] as String? ?? json['pickup_name'] as String? ?? '',
      destination: json['destination'] as String? ?? json['dropoff_name'] as String? ?? '',
      pickupLat: (json['pickupLat'] as num? ?? json['pickup_latitude'] as num? ?? 0.0).toDouble(),
      pickupLng: (json['pickupLng'] as num? ?? json['pickup_longitude'] as num? ?? 0.0).toDouble(),
      destLat: (json['destLat'] as num? ?? json['dropoff_latitude'] as num? ?? 0.0).toDouble(),
      destLng: (json['destLng'] as num? ?? json['dropoff_longitude'] as num? ?? 0.0).toDouble(),
      date: json['date'] as String? ?? json['created_at'] as String? ?? '',
      price: json['price'] as String? ?? json['fare']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      driverId: json['driverId'] as String? ?? json['driver_id'] as String? ?? '',
      driverName: json['driverName'] as String? ?? json['driver_name'] as String? ?? '',
      vehiclePlate: json['vehiclePlate'] as String? ?? json['plate_number'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? json['vehicle_type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickup': pickup,
      'destination': destination,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destLat': destLat,
      'destLng': destLng,
      'date': date,
      'price': price,
      'status': status,
      'driverId': driverId,
      'driverName': driverName,
      'vehiclePlate': vehiclePlate,
      'vehicleType': vehicleType,
    };
  }

  @override
  List<Object?> get props => [
        id,
        pickup,
        destination,
        pickupLat,
        pickupLng,
        destLat,
        destLng,
        date,
        price,
        status,
        driverId,
        driverName,
        vehiclePlate,
        vehicleType,
      ];
}
