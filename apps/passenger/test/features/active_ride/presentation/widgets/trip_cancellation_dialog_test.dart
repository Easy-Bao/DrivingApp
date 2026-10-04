import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/trip_cancellation_dialog.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: EasyRideTheme.main,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders cancellation dialog with dropdown and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (_) => const TripCancellationDialog(),
              ),
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel ride?'), findsOneWidget);
    expect(
      find.text(
        'Select a reason so EasyRide can record what happened. No cancellation fee is collected in the app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reason for cancellation'), findsOneWidget);
    expect(find.text('Select a reason'), findsOneWidget);
    expect(find.text('Keep ride'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('confirm-cancel-ride-button')),
      findsOneWidget,
    );
  });

  testWidgets('confirms discard when a reason is selected and user cancels', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => const TripCancellationDialog(),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('cancellation-reason-dropdown')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Driver is taking too long').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep ride'));
    await tester.pumpAndSettle();

    expect(find.text('Discard cancellation?'), findsOneWidget);
    expect(
      find.text(
        'You have selected a cancellation reason. Are you sure you want to discard it?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel ride?'), findsOneWidget);
    expect(find.text('Driver is taking too long'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('Keep ride'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel ride?'), findsNothing);
    expect(result, isNull);
  });

  testWidgets(
    'confirms cancel ride directly when Cancel ride button is tapped',
    (tester) async {
      String? result;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) => const TripCancellationDialog(),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('cancellation-reason-dropdown')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Changed my mind').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('confirm-cancel-ride-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel ride?'), findsNothing);
      expect(result, 'passenger_changed_mind');
    },
  );
}
