import 'package:equatable/equatable.dart';

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
