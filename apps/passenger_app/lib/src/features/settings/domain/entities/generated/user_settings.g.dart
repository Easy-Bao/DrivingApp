// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) =>
    _UserSettings(
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool,
      locationSharingEnabled: json['locationSharingEnabled'] as bool,
      preferredThemeMode: json['preferredThemeMode'] as String,
    );

Map<String, dynamic> _$UserSettingsToJson(_UserSettings instance) =>
    <String, dynamic>{
      'pushNotificationsEnabled': instance.pushNotificationsEnabled,
      'locationSharingEnabled': instance.locationSharingEnabled,
      'preferredThemeMode': instance.preferredThemeMode,
    };
