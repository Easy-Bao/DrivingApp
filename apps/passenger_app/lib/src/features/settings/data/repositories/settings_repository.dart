import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/settings/domain/entities/user_settings.dart';
import 'package:passenger_app/src/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository implements ISettingsRepository {
  final SharedPreferences _preferences;

  SettingsRepository({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _notificationsKey = 'setting_push_notifications';
  static const String _locationSharingKey = 'setting_location_sharing';
  static const String _themeModeKey = 'setting_theme_mode';

  @override
  Future<Either<Failure, UserSettings>> fetchUserSettings() async {
    try {
      final notifications = _preferences.getBool(_notificationsKey) ?? true;
      final locationSharing = _preferences.getBool(_locationSharingKey) ?? true;
      final themeMode = _preferences.getString(_themeModeKey) ?? 'system';

      return Right(
        UserSettings(
          pushNotificationsEnabled: notifications,
          locationSharingEnabled: locationSharing,
          preferredThemeMode: themeMode,
        ),
      );
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to load your settings right now. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateUserSettings(
    UserSettings settings,
  ) async {
    try {
      await _preferences.setBool(
        _notificationsKey,
        settings.pushNotificationsEnabled,
      );
      await _preferences.setBool(
        _locationSharingKey,
        settings.locationSharingEnabled,
      );
      await _preferences.setString(_themeModeKey, settings.preferredThemeMode);
      return const Right(null);
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save your settings right now. Please try again.',
        ),
      );
    }
  }
}
