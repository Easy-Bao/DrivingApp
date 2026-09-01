import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

final class const DriverAuthCredentials({
  required final String driverId,
  required final String driverName,
  required final String driverEmail,
  required final String vehicleType,
  required final String plateNumber,
  required final double rating,
  final String token = '',
  final String refreshToken = '',
}) extends Equatable {
  factory DriverAuthCredentials.fromJson(Map<String, dynamic> json) {
    return DriverAuthCredentials(
      driverId: SafeParse.toStringValue(json['driverId'] ?? json['id']),
      driverName: SafeParse.toStringValue(json['driverName'] ?? json['name']),
      driverEmail: SafeParse.toStringValue(
        json['driverEmail'] ?? json['email'],
      ),
      vehicleType: SafeParse.toStringValue(
        json['vehicleType'],
        'Vehicle type unavailable',
      ),
      plateNumber: SafeParse.toStringValue(
        json['plateNumber'],
        'Vehicle plate unavailable',
      ),
      rating: SafeParse.toDouble(json['rating']),
      token: SafeParse.toStringValue(json['token']),
      refreshToken: SafeParse.toStringValue(json['refreshToken']),
    );
  }

  String get accountId => driverId;

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'rating': rating,
      'token': token,
      'refreshToken': refreshToken,
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
    token,
    refreshToken,
  ];
}
