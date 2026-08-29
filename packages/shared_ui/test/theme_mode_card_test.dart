import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('shows a preview and a selected indicator for each mode', (
    tester,
  ) async {
    var selectedMode = ThemeMode.system;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                for (final mode in ThemeMode.values)
                  ThemeModeCard(
                    mode: mode,
                    title: mode.name,
                    description: 'Preview ${mode.name}',
                    isSelected: selectedMode == mode,
                    onTap: () => setState(() => selectedMode = mode),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('theme-mode-card-system')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-mode-card-system-selected')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('theme-mode-card-system')))
          .height,
      greaterThanOrEqualTo(118),
    );

    await tester.tap(find.byKey(const ValueKey('theme-mode-card-dark')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('theme-mode-card-dark-selected')),
      findsOneWidget,
    );
  });
}
