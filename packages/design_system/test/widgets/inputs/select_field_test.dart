import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a custom selection sheet and returns the chosen value', (
    tester,
  ) async {
    String? selectedValue;
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => EasyRideSelectField<String>(
              key: const ValueKey('custom-select'),
              value: selectedValue,
              menuTitle: 'Choose a reason',
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Select a reason',
              ),
              options: const [
                EasyRideSelectOption<String>(
                  value: 'first',
                  label: 'First reason',
                ),
                EasyRideSelectOption<String>(
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

    expect(find.byType(EasyRideSelectField<String>), findsOneWidget);
    expect(find.text('Select a reason'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('custom-select')));
    await tester.pumpAndSettle();

    expect(find.text('Choose a reason'), findsOneWidget);
    expect(find.text('First reason'), findsOneWidget);
    expect(find.text('Second reason'), findsOneWidget);
    expect(find.byType(EasyRideSelectField<String>), findsOneWidget);

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
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: EasyRideSelectField<String>(
            key: const ValueKey('custom-select'),
            value: selectedValue,
            decoration: const InputDecoration(hintText: 'Select a reason'),
            options: const [
              EasyRideSelectOption<String>(
                value: 'first',
                label: 'First reason',
              ),
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
