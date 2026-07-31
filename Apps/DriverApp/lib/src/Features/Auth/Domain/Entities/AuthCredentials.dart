import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_credentials.g.dart';

@JsonSerializable()
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

  factory AuthCredentials.fromJson(Map<String, dynamic> json) =>
      _$AuthCredentialsFromJson(json);

  Map<String, dynamic> toJson() => _$AuthCredentialsToJson(this);

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

