import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final bool pushNotificationsEnabled;
  final bool locationSharingEnabled;
  final String preferredThemeMode;

  const UserSettings({
    required this.pushNotificationsEnabled,
    required this.locationSharingEnabled,
    required this.preferredThemeMode,
  });

  UserSettings copyWith({
    bool? pushNotificationsEnabled,
    bool? locationSharingEnabled,
    String? preferredThemeMode,
  }) {
    return UserSettings(
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      locationSharingEnabled:
          locationSharingEnabled ?? this.locationSharingEnabled,
      preferredThemeMode: preferredThemeMode ?? this.preferredThemeMode,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushNotificationsEnabled:
          json['push_notifications_enabled'] as bool? ?? true,
      locationSharingEnabled: json['location_sharing_enabled'] as bool? ?? true,
      preferredThemeMode: json['preferred_theme_mode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_notifications_enabled': pushNotificationsEnabled,
      'location_sharing_enabled': locationSharingEnabled,
      'preferred_theme_mode': preferredThemeMode,
    };
  }

  @override
  List<Object?> get props => [
        pushNotificationsEnabled,
        locationSharingEnabled,
        preferredThemeMode,
      ];
}
