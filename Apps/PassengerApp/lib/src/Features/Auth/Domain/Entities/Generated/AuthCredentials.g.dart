// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../auth_credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthCredentials _$AuthCredentialsFromJson(Map<String, dynamic> json) =>
    _AuthCredentials(
      passengerId: json['passengerId'] as String,
      passengerName: json['passengerName'] as String,
      passengerEmail: json['passengerEmail'] as String,
      passengerPhone: json['passengerPhone'] as String,
      token: json['token'] as String,
      needsVerification: json['needsVerification'] as bool? ?? false,
    );

Map<String, dynamic> _$AuthCredentialsToJson(_AuthCredentials instance) =>
    <String, dynamic>{
      'passengerId': instance.passengerId,
      'passengerName': instance.passengerName,
      'passengerEmail': instance.passengerEmail,
      'passengerPhone': instance.passengerPhone,
      'token': instance.token,
      'needsVerification': instance.needsVerification,
    };
