import 'package:design_system/design_system.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/driver_dashboard/driver_incoming_request_dialog.dart';
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

  testWidgets('renders incoming ride request details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverIncomingRequestDialog(
            bid: testBid,
            submittingBidId: null,
            onDecline: () {},
            onAccept: () {},
          ),
        ),
      ),
    );

    expect(find.text('Ride Request'), findsOneWidget);
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
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverIncomingRequestDialog(
            bid: testBid,
            submittingBidId: null,
            onDecline: () {},
            onAccept: () {},
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
      find.byKey(const ValueKey('incoming-request-accept-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'interpolates countdown progress smoothly via animation controller',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
          home: Scaffold(
            body: DriverIncomingRequestDialog(
              bid: testBid,
              submittingBidId: null,
              onDecline: () {},
              onAccept: () {},
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

  testWidgets('triggers onDecline and onAccept callbacks', (tester) async {
    var declined = false;
    var accepted = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverIncomingRequestDialog(
            bid: testBid,
            submittingBidId: null,
            onDecline: () => declined = true,
            onAccept: () => accepted = true,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('incoming-request-decline-button')),
    );
    expect(declined, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('incoming-request-accept-button')),
    );
    expect(accepted, isTrue);
  });

  testWidgets('latches the accept action against rapid double taps', (
    tester,
  ) async {
    var accepted = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverIncomingRequestDialog(
            bid: testBid,
            submittingBidId: null,
            onDecline: () {},
            onAccept: () => accepted++,
          ),
        ),
      ),
    );

    final acceptButton = find.byKey(
      const ValueKey('incoming-request-accept-button'),
    );
    await tester.tap(acceptButton);
    await tester.tap(acceptButton);

    expect(accepted, 1);
  });

  testWidgets('triggers onTimeout when countdown expires', (tester) async {
    var timedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverIncomingRequestDialog(
            bid: {
              ...testBid,
              'expires_at': DateTime.now()
                  .add(const Duration(seconds: 2))
                  .toIso8601String(),
            },
            submittingBidId: null,
            onDecline: () {},
            onAccept: () {},
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
