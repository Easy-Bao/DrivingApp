import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/auth_credentials.freezed.dart';
part 'generated/auth_credentials.g.dart';

@freezed
abstract class AuthCredentials with _$AuthCredentials {
  const factory AuthCredentials({
    required String driverId,
    required String driverName,
    required String driverEmail,
    required String vehicleType,
    required String plateNumber,
    required double rating,
  }) = _AuthCredentials;

  factory AuthCredentials.fromJson(Map<String, dynamic> json) =>
      _$AuthCredentialsFromJson(json);
}
