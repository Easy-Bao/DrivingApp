import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/settings/domain/entities/user_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitialState extends SettingsState {
  const SettingsInitialState();
}

class SettingsLoadingState extends SettingsState {
  const SettingsLoadingState();
}

class SettingsLoadedState extends SettingsState {
  final UserSettings settings;

  const SettingsLoadedState(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsErrorState extends SettingsState {
  final String message;

  const SettingsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
