import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeModeKey = 'setting_theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    unawaited(_loadPersistedThemeMode());
  }

  Future<void> _loadPersistedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeModeKey) ?? 'system';
      emit(_parseThemeMode(modeString));
    } catch (_) {}
  }

  Future<void> changeThemeMode(String modeString) async {
    final mode = _parseThemeMode(modeString);
    emit(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, modeString);
    } catch (_) {}
  }

  ThemeMode _parseThemeMode(String modeString) {
    switch (modeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
