import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

class const RideHistory({
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
  this.driverRating,
}) extends Equatable {
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
  final double? driverRating;

  String get displayDriverName {
    final value = driverName.trim();
    return value.isEmpty ? 'Driver' : value;
  }

  String get displayVehicleSummary {
    final details = [
      vehicleType.trim(),
      vehiclePlate.trim(),
    ].where((value) => value.isNotEmpty).toList();
    return details.isEmpty
        ? 'Vehicle details unavailable'
        : details.join(' • ');
  }

  factory fromJson(Map<String, dynamic> json) {
    final {
      'id': rawId,
      'pickup': rawPickup,
      'destination': rawDestination,
      'pickup_latitude': rawPickupLat,
      'pickup_longitude': rawPickupLng,
      'destination_latitude': rawDestLat,
      'destination_longitude': rawDestLng,
      'date': rawDate,
      'price': rawPrice,
      'status': rawStatus,
      'driver_id': rawDriverId,
      'driver_name': rawDriverName,
      'vehicle_plate': rawVehiclePlate,
      'vehicle_type': rawVehicleType,
      'driver_rating': rawDriverRating,
    } = _canonicalPayload(
      json,
    );

    return RideHistory(
      id: SafeParse.toStringValue(rawId),
      pickup: SafeParse.toStringValue(rawPickup),
      destination: SafeParse.toStringValue(rawDestination),
      pickupLat: SafeParse.toDouble(rawPickupLat),
      pickupLng: SafeParse.toDouble(rawPickupLng),
      destLat: SafeParse.toDouble(rawDestLat),
      destLng: SafeParse.toDouble(rawDestLng),
      date: SafeParse.toStringValue(rawDate),
      price: SafeParse.toStringValue(rawPrice),
      status: SafeParse.toStringValue(rawStatus),
      driverId: SafeParse.toStringValue(rawDriverId),
      driverName: SafeParse.toStringValue(rawDriverName),
      vehiclePlate: SafeParse.toStringValue(rawVehiclePlate),
      vehicleType: SafeParse.toStringValue(rawVehicleType),
      driverRating: SafeParse.toNullableDouble(rawDriverRating),
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
      'driverRating': driverRating,
    };
  }

  RideHistory copyWith({
    String? id,
    String? pickup,
    String? destination,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
    String? date,
    String? price,
    String? status,
    String? driverId,
    String? driverName,
    String? vehiclePlate,
    String? vehicleType,
    double? driverRating,
  }) {
    return RideHistory(
      id: id ?? this.id,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      destLat: destLat ?? this.destLat,
      destLng: destLng ?? this.destLng,
      date: date ?? this.date,
      price: price ?? this.price,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      driverRating: driverRating ?? this.driverRating,
    );
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
    driverRating,
  ];
}

Map<String, Object?> _canonicalPayload(Map<String, dynamic> json) => {
  'id': json['id'],
  'pickup': json['pickup'] ?? json['pickup_name'],
  'destination': json['destination'] ?? json['dropoff_name'],
  'pickup_latitude': json['pickupLat'] ?? json['pickup_latitude'],
  'pickup_longitude': json['pickupLng'] ?? json['pickup_longitude'],
  'destination_latitude': json['destLat'] ?? json['dropoff_latitude'],
  'destination_longitude': json['destLng'] ?? json['dropoff_longitude'],
  'date': json['date'] ?? json['completed_at'] ?? json['created_at'],
  'price': json['price'] ?? json['fare'],
  'status': json['status'],
  'driver_id': json['driverId'] ?? json['driver_id'],
  'driver_name': json['driverName'] ?? json['driver_name'],
  'vehicle_plate': json['vehiclePlate'] ?? json['plate_number'],
  'vehicle_type': json['vehicleType'] ?? json['vehicle_type'],
  'driver_rating': json['driver_rating'] ?? json['driverRating'],
};
