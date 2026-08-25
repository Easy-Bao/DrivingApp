import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/settings/data/repositories/settings_repository.dart';
import 'package:passenger_app/src/features/settings/domain/entities/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late SettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    repository = SettingsRepository(preferences: preferences);
  });

  test('reads defaults from the injected preferences instance', () async {
    final result = await repository.fetchUserSettings();

    expect(result.isRight(), isTrue);
    expect(
      result.getOrElse((_) => throw StateError('Expected settings.')),
      const UserSettings(
        pushNotificationsEnabled: true,
        locationSharingEnabled: true,
        preferredThemeMode: 'system',
      ),
    );
  });

  test('persists every setting field through the repository', () async {
    const settings = UserSettings(
      pushNotificationsEnabled: false,
      locationSharingEnabled: false,
      preferredThemeMode: 'dark',
    );

    final result = await repository.updateUserSettings(settings);

    expect(result.isRight(), isTrue);
    final fetched = await repository.fetchUserSettings();
    expect(
      fetched.getOrElse((_) => throw StateError('Expected saved settings.')),
      settings,
    );
  });
}
