import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/active_trip_exit_dialog.dart';

void main() {
  testWidgets('offers safe actions for an active trip', (tester) async {
    ActiveTripExitAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedAction = await showDialog<ActiveTripExitAction>(
                  context: context,
                  builder: (_) =>
                      const ActiveTripExitDialog(driverName: 'Alex'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Trip in progress'), findsOneWidget);
    expect(find.text('Keep tracking'), findsOneWidget);
    expect(find.text('Go to home'), findsOneWidget);
    expect(find.text('Cancel ride'), findsOneWidget);

    await tester.tap(find.text('Cancel ride'));
    await tester.pumpAndSettle();

    expect(selectedAction, ActiveTripExitAction.cancel);
  });
}
