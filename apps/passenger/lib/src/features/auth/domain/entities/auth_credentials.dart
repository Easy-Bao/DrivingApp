import 'package:equatable/equatable.dart';

final class const PassengerAuthCredentials({
  required final String passengerId,
  required final String passengerName,
  required final String passengerEmail,
  required final String passengerPhone,
  required final String token,
  final String refreshToken = '',
  final bool needsVerification = false,
}) extends Equatable {
  factory fromJson(Map<String, dynamic> json) {
    return PassengerAuthCredentials(
      passengerId:
          json['passengerId']?.toString() ?? json['id']?.toString() ?? '',
      passengerName:
          json['passengerName'] as String? ?? json['name'] as String? ?? '',
      passengerEmail:
          json['passengerEmail'] as String? ?? json['email'] as String? ?? '',
      passengerPhone:
          json['passengerPhone'] as String? ?? json['phone'] as String? ?? '',
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      needsVerification: json['needsVerification'] as bool? ?? false,
    );
  }

  String get accountId => passengerId;

  Map<String, dynamic> toJson() {
    return {
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerEmail': passengerEmail,
      'passengerPhone': passengerPhone,
      'token': token,
      'refreshToken': refreshToken,
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
    refreshToken,
    needsVerification,
  ];
}
