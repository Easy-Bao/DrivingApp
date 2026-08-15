import 'package:equatable/equatable.dart';
import 'package:shared_core/shared_core.dart';

class AuthCredentials extends Equatable {
  final String driverId;
  final String driverName;
  final String driverEmail;
  final String vehicleType;
  final String plateNumber;
  final double rating;

  const AuthCredentials({
    required this.driverId,
    required this.driverName,
    required this.driverEmail,
    required this.vehicleType,
    required this.plateNumber,
    required this.rating,
  });

  factory AuthCredentials.fromJson(Map<String, dynamic> json) {
    return AuthCredentials(
      driverId: SafeParse.toStringValue(json['driverId'] ?? json['id']),
      driverName: SafeParse.toStringValue(json['driverName'] ?? json['name']),
      driverEmail: SafeParse.toStringValue(json['driverEmail'] ?? json['email']),
      vehicleType: SafeParse.toStringValue(
        json['vehicleType'],
        'Vehicle type unavailable',
      ),
      plateNumber: SafeParse.toStringValue(
        json['plateNumber'],
        'Vehicle plate unavailable',
      ),
      rating: SafeParse.toDouble(json['rating']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'rating': rating,
    };
  }

  @override
  List<Object?> get props => [
    driverId,
    driverName,
    driverEmail,
    vehicleType,
    plateNumber,
    rating,
  ];
}
