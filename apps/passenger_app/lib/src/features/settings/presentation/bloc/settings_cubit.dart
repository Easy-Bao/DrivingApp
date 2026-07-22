import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:passenger_app/src/features/settings/presentation/bloc/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsCubit({required this.settingsRepository})
      : super(const SettingsInitialState());

  Future<void> loadSettings() async {
    emit(const SettingsLoadingState());
    final result = await settingsRepository.fetchUserSettings();

    result.fold(
      (failure) => emit(SettingsErrorState(failure.message)),
      (settings) => emit(SettingsLoadedState(settings)),
    );
  }

  Future<void> togglePushNotifications(bool enabled) async {
    if (state is SettingsLoadedState) {
      final current = (state as SettingsLoadedState).settings;
      final updated = current.copyWith(pushNotificationsEnabled: enabled);
      emit(SettingsLoadedState(updated));
      await settingsRepository.updateUserSettings(updated);
    }
  }

  Future<void> toggleLocationSharing(bool enabled) async {
    if (state is SettingsLoadedState) {
      final current = (state as SettingsLoadedState).settings;
      final updated = current.copyWith(locationSharingEnabled: enabled);
      emit(SettingsLoadedState(updated));
    }
  }

  Future<void> updateThemeMode(String themeMode) async {
    if (state is SettingsLoadedState) {
      final current = (state as SettingsLoadedState).settings;
      final updated = current.copyWith(preferredThemeMode: themeMode);
      emit(SettingsLoadedState(updated));
      await settingsRepository.updateUserSettings(updated);
    }
  }
}
