import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/settings/bloc/settings/settings_cubit.dart';
import 'package:passenger_app/src/features/settings/bloc/settings/settings_state.dart';
import 'package:passenger_app/src/features/settings/domain/entities/user_settings.dart';
import 'package:passenger_app/src/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:shared_core/shared_core.dart';

class _FakeSettingsRepository implements ISettingsRepository {
  UserSettings settings = const UserSettings(
    pushNotificationsEnabled: true,
    locationSharingEnabled: true,
    preferredThemeMode: 'system',
  );

  @override
  Future<Either<Failure, UserSettings>> fetchUserSettings() async {
    return Right(settings);
  }

  @override
  Future<Either<Failure, void>> updateUserSettings(
    UserSettings nextSettings,
  ) async {
    settings = nextSettings;
    return const Right(null);
  }
}

void main() {
  test('location sharing changes are persisted by the Cubit', () async {
    final repository = _FakeSettingsRepository();
    final cubit = SettingsCubit(settingsRepository: repository);

    await cubit.loadSettings();
    await cubit.toggleLocationSharing(false);

    expect(repository.settings.locationSharingEnabled, isFalse);
    expect(
      (cubit.state as SettingsLoadedState).settings.locationSharingEnabled,
      isFalse,
    );
    await cubit.close();
  });
}
