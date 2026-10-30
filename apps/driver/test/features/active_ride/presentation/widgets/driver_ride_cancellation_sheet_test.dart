import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_ride_cancellation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.main,
      home: Scaffold(body: child),
    );
  }

  testWidgets(
    'renders cancellation sheet with dropdown, info card, and actions',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showRideCancellationSheet(context),
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
        find.text('Choose the reason that best describes what happened.'),
        findsOneWidget,
      );
      expect(find.text('Reason for cancellation'), findsOneWidget);
      expect(find.text('Select a reason'), findsOneWidget);
      expect(find.textContaining('Passenger No-Show'), findsOneWidget);
      expect(find.text('Keep ride'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('confirm-driver-cancel-ride-button')),
        findsOneWidget,
      );

      final cancelButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('confirm-driver-cancel-ride-button')),
      );
      expect(cancelButton.onPressed, isNull);
    },
  );

  testWidgets(
    'keeps the ride without an extra confirmation after selecting a reason',
    (tester) async {
      CancellationChoice? result;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showRideCancellationSheet(context);
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
        find.byKey(const ValueKey('driver-cancellation-reason-dropdown')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vehicle problem').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep ride'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel ride?'), findsNothing);
      expect(result, isNull);
    },
  );

  testWidgets('confirms cancel ride when reason is selected and tapped', (
    tester,
  ) async {
    CancellationChoice? result;

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showRideCancellationSheet(context);
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
      find.byKey(const ValueKey('driver-cancellation-reason-dropdown')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passenger is unreachable').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('confirm-driver-cancel-ride-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancel ride?'), findsNothing);
    expect(result, isNotNull);
    expect(result!.reason, 'passenger_unreachable');
    expect(result!.details, isEmpty);
  });

  testWidgets('requires details when choosing Other', (tester) async {
    CancellationChoice? result;

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showRideCancellationSheet(context);
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
      find.byKey(const ValueKey('driver-cancellation-reason-dropdown')),
    );
    await tester.pumpAndSettle();

    final otherOption = find.text('Other (requires details)').last;
    await tester.scrollUntilVisible(
      otherOption,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(otherOption);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('driver-cancellation-details')),
      findsOneWidget,
    );

    // Tap cancel ride without details
    await tester.tap(
      find.byKey(const ValueKey('confirm-driver-cancel-ride-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add details when choosing Other.'), findsOneWidget);
    expect(result, isNull);

    // Enter details
    await tester.enterText(
      find.byKey(const ValueKey('driver-cancellation-details')),
      'Flat tire on expressway',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('confirm-driver-cancel-ride-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancel ride?'), findsNothing);
    expect(result, isNotNull);
    expect(result!.reason, 'other');
    expect(result!.details, 'Flat tire on expressway');
  });
}
