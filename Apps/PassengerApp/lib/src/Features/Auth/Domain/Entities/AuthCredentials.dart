import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_credentials.g.dart';

@JsonSerializable()
class AuthCredentials extends Equatable {
  final String passengerId;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;
  final String token;
  final bool needsVerification;

  const AuthCredentials({
    required this.passengerId,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
    required this.token,
    this.needsVerification = false,
  });

  factory AuthCredentials.fromJson(Map<String, dynamic> json) =>
      _$AuthCredentialsFromJson(json);

  Map<String, dynamic> toJson() => _$AuthCredentialsToJson(this);

  @override
  List<Object?> get props => [
        passengerId,
        passengerName,
        passengerEmail,
        passengerPhone,
        token,
        needsVerification,
      ];
}

