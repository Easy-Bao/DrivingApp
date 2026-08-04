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

  factory AuthCredentials.fromJson(Map<String, dynamic> json) {
    return AuthCredentials(
      passengerId:
          json['passengerId']?.toString() ?? json['id']?.toString() ?? '',
      passengerName:
          json['passengerName'] as String? ?? json['name'] as String? ?? '',
      passengerEmail:
          json['passengerEmail'] as String? ?? json['email'] as String? ?? '',
      passengerPhone:
          json['passengerPhone'] as String? ?? json['phone'] as String? ?? '',
      token: json['token'] as String? ?? '',
      needsVerification: json['needsVerification'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerEmail': passengerEmail,
      'passengerPhone': passengerPhone,
      'token': token,
      'needsVerification': needsVerification,
    };
  }

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
