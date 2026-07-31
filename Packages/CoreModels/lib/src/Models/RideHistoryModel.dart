import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Generated/RideHistoryModel.g.dart';

@JsonSerializable()
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

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$RideHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$RideHistoryModelToJson(this);

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

