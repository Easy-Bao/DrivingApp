import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/user_settings.freezed.dart';
part 'generated/user_settings.g.dart';

@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    required bool pushNotificationsEnabled,
    required bool locationSharingEnabled,
    required String preferredThemeMode,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
