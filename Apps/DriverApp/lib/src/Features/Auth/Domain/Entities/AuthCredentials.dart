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

  factory AuthCredentials.fromJson(Map<String, dynamic> json) {
    return AuthCredentials(
      driverId: json['driverId'] as String? ?? json['id'] as String? ?? '',
      driverName: json['driverName'] as String? ?? json['name'] as String? ?? '',
      driverEmail: json['driverEmail'] as String? ?? json['email'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? 'Bao Bao',
      plateNumber: json['plateNumber'] as String? ?? 'ABC 1234',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
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
