import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('repeated activation opens only one selection sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSelectField<String>(
            options: const [AppSelectOption(value: 'first', label: 'First')],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final field = find.byType(AppSelectField<String>);
    final inkWell = tester.widget<InkWell>(
      find.descendant(of: field, matching: find.byType(InkWell)),
    );
    inkWell.onTap!();
    inkWell.onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('ignores a selection if the field becomes disabled', (
    tester,
  ) async {
    var enabled = true;
    var changes = 0;
    late StateSetter updateField;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateField = setState;
              return AppSelectField<String>(
                options: const [
                  AppSelectOption(value: 'first', label: 'First'),
                ],
                onChanged: enabled ? (_) => changes++ : null,
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppSelectField<String>));
    await tester.pumpAndSettle();
    updateField(() => enabled = false);
    await tester.pump();
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('opens a custom selection sheet and returns the chosen value', (
    tester,
  ) async {
    String? selectedValue;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppSelectField<String>(
              key: const ValueKey('custom-select'),
              value: selectedValue,
              menuTitle: 'Choose a reason',
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Select a reason',
              ),
              options: const [
                AppSelectOption<String>(value: 'first', label: 'First reason'),
                AppSelectOption<String>(
                  value: 'second',
                  label: 'Second reason',
                ),
              ],
              onChanged: (value) => setState(() => selectedValue = value),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AppSelectField<String>), findsOneWidget);
    expect(find.text('Select a reason'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('custom-select')));
    await tester.pumpAndSettle();

    expect(find.text('Choose a reason'), findsOneWidget);
    expect(find.text('First reason'), findsOneWidget);
    expect(find.text('Second reason'), findsOneWidget);
    expect(find.byType(AppSelectField<String>), findsOneWidget);

    await tester.tap(find.text('Second reason'));
    await tester.pumpAndSettle();

    expect(selectedValue, 'second');
    expect(find.text('Second reason'), findsOneWidget);
    expect(find.text('Choose a reason'), findsNothing);
  });

  testWidgets('dismisses the custom selection sheet without changing value', (
    tester,
  ) async {
    String? selectedValue;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: AppSelectField<String>(
            key: const ValueKey('custom-select'),
            value: selectedValue,
            decoration: const InputDecoration(hintText: 'Select a reason'),
            options: const [
              AppSelectOption<String>(value: 'first', label: 'First reason'),
            ],
            onChanged: (value) => selectedValue = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('custom-select')));
    await tester.pumpAndSettle();
    expect(find.text('First reason'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(selectedValue, isNull);
    expect(find.text('First reason'), findsNothing);
  });
}
