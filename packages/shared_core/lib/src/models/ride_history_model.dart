import 'package:equatable/equatable.dart';
import 'package:shared_core/src/utils/safe_parse.dart';

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
  final double? driverRating;

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
    this.driverRating,
  });

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

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) {
    return RideHistoryModel(
      id: SafeParse.toStringValue(json['id']),
      pickup: SafeParse.toStringValue(json['pickup'] ?? json['pickup_name']),
      destination: SafeParse.toStringValue(
        json['destination'] ?? json['dropoff_name'],
      ),
      pickupLat: SafeParse.toDouble(
        json['pickupLat'] ?? json['pickup_latitude'],
      ),
      pickupLng: SafeParse.toDouble(
        json['pickupLng'] ?? json['pickup_longitude'],
      ),
      destLat: SafeParse.toDouble(json['destLat'] ?? json['dropoff_latitude']),
      destLng: SafeParse.toDouble(json['destLng'] ?? json['dropoff_longitude']),
      date: SafeParse.toStringValue(
        json['date'] ?? json['completed_at'] ?? json['created_at'],
      ),
      price: SafeParse.toStringValue(json['price'] ?? json['fare']),
      status: SafeParse.toStringValue(json['status']),
      driverId: SafeParse.toStringValue(json['driverId'] ?? json['driver_id']),
      driverName: SafeParse.toStringValue(
        json['driverName'] ?? json['driver_name'],
      ),
      vehiclePlate: SafeParse.toStringValue(
        json['vehiclePlate'] ?? json['plate_number'],
      ),
      vehicleType: SafeParse.toStringValue(
        json['vehicleType'] ?? json['vehicle_type'],
      ),
      driverRating: SafeParse.toNullableDouble(
        json['driver_rating'] ?? json['driverRating'],
      ),
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

  RideHistoryModel copyWith({
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
    return RideHistoryModel(
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
