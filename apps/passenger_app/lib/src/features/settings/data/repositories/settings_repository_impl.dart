import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/settings/domain/entities/user_settings.dart';
import 'package:passenger_app/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _notificationsKey = 'setting_push_notifications';
  static const String _locationSharingKey = 'setting_location_sharing';
  static const String _themeModeKey = 'setting_theme_mode';

  @override
  Future<Either<Failure, UserSettings>> fetchUserSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getBool(_notificationsKey) ?? true;
      final locationSharing = prefs.getBool(_locationSharingKey) ?? true;
      final themeMode = prefs.getString(_themeModeKey) ?? 'system';

      return Right(
        UserSettings(
          pushNotificationsEnabled: notifications,
          locationSharingEnabled: locationSharing,
          preferredThemeMode: themeMode,
        ),
      );
    } catch (error) {
      return Left(CacheFailure('Failed to load settings: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserSettings(
    UserSettings settings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, settings.pushNotificationsEnabled);
      await prefs.setBool(_locationSharingKey, settings.locationSharingEnabled);
      await prefs.setString(_themeModeKey, settings.preferredThemeMode);
      return const Right(null);
    } catch (error) {
      return Left(CacheFailure('Failed to save settings: $error'));
    }
  }
}
