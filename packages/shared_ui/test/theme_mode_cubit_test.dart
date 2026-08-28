import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('codec defaults invalid and absent preferences to system', () {
    expect(ThemeModeCodec.decode(null), ThemeMode.system);
    expect(ThemeModeCodec.decode('unexpected'), ThemeMode.system);
    expect(ThemeModeCodec.decode(' LIGHT '), ThemeMode.light);
    expect(ThemeModeCodec.decode('dark'), ThemeMode.dark);
    expect(ThemeModeCodec.encode(ThemeMode.system), 'system');
  });

  test('selection applies before persistence completes', () async {
    final persistence = Completer<bool>();
    String? savedValue;
    final cubit = ThemeModeCubit(
      initialMode: ThemeMode.system,
      savePreference: (value) {
        savedValue = value;
        return persistence.future;
      },
    );
    addTearDown(cubit.close);

    final result = cubit.setThemeMode(ThemeMode.dark);

    expect(cubit.state, ThemeMode.dark);
    expect(savedValue, 'dark');
    persistence.complete(true);
    expect(await result, isTrue);
  });

  test(
    'persistence failures are reported without undoing the live choice',
    () async {
      final cubit = ThemeModeCubit(
        initialMode: ThemeMode.light,
        savePreference: (_) => throw StateError('storage unavailable'),
      );
      addTearDown(cubit.close);

      final persisted = await cubit.setThemeMode(ThemeMode.dark);

      expect(persisted, isFalse);
      expect(cubit.state, ThemeMode.dark);
    },
  );
}
