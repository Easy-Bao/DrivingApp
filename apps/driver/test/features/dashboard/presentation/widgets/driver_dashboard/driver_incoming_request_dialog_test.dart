import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/driver_incoming_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testBid = {
    'id': 'bid-123',
    'pickup_name': 'Ayala Center Cebu',
    'dropoff_name': 'IT Park Tower 1',
    'fare_amount': 25000,
    'distance_km': 3.5,
    'passenger_note': 'Waiting near the main entrance',
    'expires_at': DateTime.now()
        .add(const Duration(seconds: 30))
        .toIso8601String(),
  };

  testWidgets('renders open ride offer details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: IncomingRequestDialog(
            bid: testBid,
            submittingBidId: null,
            onDecline: () {},
            onSubmitOffer: () {},
          ),
        ),
      ),
    );

    expect(find.text('Open Ride Offer'), findsOneWidget);
    expect(find.text('Submit Offer'), findsOneWidget);
    expect(find.text('Ayala Center Cebu'), findsOneWidget);
    expect(find.text('IT Park Tower 1'), findsOneWidget);
    expect(find.text('₱250'), findsOneWidget);
    expect(find.text('3.5 km away'), findsOneWidget);
    expect(find.text('Waiting near the main entrance'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('incoming-request-countdown-progress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('incoming-request-linear-progress')),
      findsOneWidget,
    );
  });

  testWidgets('keeps actions reachable in landscape viewports', (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: IncomingRequestDialog(
            bid: testBid,
            submittingBidId: null,
            onDecline: () {},
            onSubmitOffer: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('incoming-request-scroll-view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('incoming-request-decline-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('incoming-request-submit-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'interpolates countdown progress smoothly via animation controller',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Scaffold(
            body: IncomingRequestDialog(
              bid: testBid,
              submittingBidId: null,
              onDecline: () {},
              onSubmitOffer: () {},
              totalDuration: const Duration(seconds: 30),
            ),
          ),
        ),
      );

      final initialProgress = tester.widget<CircularProgressIndicator>(
        find.byKey(const ValueKey('incoming-request-countdown-progress')),
      );
      expect(initialProgress.value, isNotNull);
      final startVal = initialProgress.value!;

      await tester.pump(const Duration(milliseconds: 250));
      final quarterSecondProgress = tester.widget<CircularProgressIndicator>(
        find.byKey(const ValueKey('incoming-request-countdown-progress')),
      );
      expect(quarterSecondProgress.value, lessThan(startVal));

      await tester.pump(const Duration(milliseconds: 500));
      final threeQuarterSecondProgress = tester
          .widget<CircularProgressIndicator>(
            find.byKey(const ValueKey('incoming-request-countdown-progress')),
          );
      expect(
        threeQuarterSecondProgress.value,
        lessThan(quarterSecondProgress.value!),
      );
    },
  );

  testWidgets('triggers onDecline and onSubmitOffer callbacks', (tester) async {
    var declined = false;
    var submittedOffer = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: IncomingRequestDialog(
            bid: testBid,
            submittingBidId: null,
            onDecline: () => declined = true,
            onSubmitOffer: () => submittedOffer = true,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('incoming-request-decline-button')),
    );
    expect(declined, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('incoming-request-submit-button')),
    );
    expect(submittedOffer, isTrue);
  });

  testWidgets('show cannot dismiss from the barrier or system back', (
    tester,
  ) async {
    var declined = false;
    var submittedOffer = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => unawaited(
                  IncomingRequestDialog.show(
                    context,
                    bid: testBid,
                    onDecline: () => declined = true,
                    onSubmitOffer: () => submittedOffer = true,
                  ),
                ),
                child: const Text('Show request'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(IncomingRequestDialog), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(IncomingRequestDialog), findsOneWidget);
    expect(declined, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(IncomingRequestDialog), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('incoming-request-decline-button')),
    );
    await tester.pump();
    expect(declined, isTrue);
    expect(
      tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.byType(IncomingRequestDialog), findsNothing);

    await tester.tap(find.text('Show request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const ValueKey('incoming-request-submit-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(IncomingRequestDialog), findsNothing);
    expect(submittedOffer, isTrue);
  });

  testWidgets('latches offer submission against rapid double taps', (
    tester,
  ) async {
    var submissions = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: IncomingRequestDialog(
            bid: testBid,
            submittingBidId: null,
            onDecline: () {},
            onSubmitOffer: () => submissions++,
          ),
        ),
      ),
    );

    final submitButton = find.byKey(
      const ValueKey('incoming-request-submit-button'),
    );
    await tester.tap(submitButton);
    await tester.tap(submitButton);

    expect(submissions, 1);
  });

  testWidgets('triggers onTimeout when countdown expires', (tester) async {
    var timedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: IncomingRequestDialog(
            bid: {
              ...testBid,
              'expires_at': DateTime.now()
                  .add(const Duration(seconds: 2))
                  .toIso8601String(),
            },
            submittingBidId: null,
            onDecline: () {},
            onSubmitOffer: () {},
            onTimeout: () => timedOut = true,
            totalDuration: const Duration(seconds: 2),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    expect(timedOut, isTrue);
  });
}
