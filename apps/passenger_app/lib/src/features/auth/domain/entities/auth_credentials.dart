import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/auth_credentials.freezed.dart';
part 'generated/auth_credentials.g.dart';

@freezed
abstract class AuthCredentials with _$AuthCredentials {
  const factory AuthCredentials({
    required String passengerId,
    required String passengerName,
    required String passengerEmail,
    required String passengerPhone,
    required String token,
    @Default(false) bool needsVerification,
  }) = _AuthCredentials;

  factory AuthCredentials.fromJson(Map<String, dynamic> json) =>
      _$AuthCredentialsFromJson(json);
}
