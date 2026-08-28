import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const appThemeModePreferenceKey = 'setting_theme_mode';

typedef ThemeModePreferenceSaver = Future<bool> Function(String value);

class ThemeModeCodec {
  ThemeModeCodec._();

  static ThemeMode decode(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String encode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };
  }
}

/// Owns the app-wide appearance choice and persists it through composition.
class ThemeModeCubit extends Cubit<ThemeMode> {
  final ThemeModePreferenceSaver _savePreference;

  ThemeModeCubit({
    required ThemeMode initialMode,
    required ThemeModePreferenceSaver savePreference,
  }) : _savePreference = savePreference,
       super(initialMode);

  /// Applies the choice immediately and reports whether persistence succeeded.
  Future<bool> setThemeMode(ThemeMode mode) async {
    if (state != mode) emit(mode);
    try {
      return await _savePreference(ThemeModeCodec.encode(mode));
    } catch (_) {
      return false;
    }
  }
}
