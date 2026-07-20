import 'package:equatable/equatable.dart';

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
