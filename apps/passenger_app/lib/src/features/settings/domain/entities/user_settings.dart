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

  @override
  List<Object?> get props => [
        pushNotificationsEnabled,
        locationSharingEnabled,
        preferredThemeMode,
      ];
}
