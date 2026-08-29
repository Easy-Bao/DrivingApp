import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/settings/view/appearance_page.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('applies and persists a selected appearance immediately', (
    tester,
  ) async {
    final savedModes = <String>[];
    final cubit = ThemeModeCubit(
      initialMode: ThemeMode.system,
      savePreference: (value) async {
        savedModes.add(value);
        return true;
      },
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<ThemeModeCubit>.value(
        value: cubit,
        child: BlocBuilder<ThemeModeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            theme: EasyRideTheme.light,
            darkTheme: EasyRideTheme.dark,
            themeMode: mode,
            home: AppearancePage(onBack: () {}),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('theme-mode-card-system-selected')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('theme-mode-card-dark')));
    await tester.pumpAndSettle();

    expect(cubit.state, ThemeMode.dark);
    expect(savedModes, ['dark']);
    expect(
      find.byKey(const ValueKey('theme-mode-card-dark-selected')),
      findsOneWidget,
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      EasyRideTheme.dark.scaffoldBackgroundColor,
    );
    expect(tester.takeException(), isNull);
  });
}
