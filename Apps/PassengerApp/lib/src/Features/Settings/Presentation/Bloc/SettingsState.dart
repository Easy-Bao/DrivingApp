import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:passenger_app/src/Features/Settings/Domain/Entities/UserSettings.dart';

part 'generated/settings_state.freezed.dart';

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = SettingsInitialState;
  const factory SettingsState.loading() = SettingsLoadingState;
  const factory SettingsState.loaded(UserSettings settings) =
      SettingsLoadedState;
  const factory SettingsState.error(String message) = SettingsErrorState;
}
