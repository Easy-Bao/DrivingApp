import 'package:design_system/design_system.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/driver_pool_bid_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final session = <String, dynamic>{
    'id': 'session-1',
    'pickup_name': 'Ayala Center Cebu',
    'dropoff_name': 'IT Park Tower 1',
    'offered_fare': 25000,
    'distance_km': 3.5,
    'expires_at': DateTime.now()
        .add(const Duration(seconds: 30))
        .toIso8601String(),
  };

  testWidgets('labels the action as submitting an offer', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: PoolBidCard(
            bid: session,
            submittingBidId: null,
            onDecline: () {},
            onSubmitOffer: () => submitted = true,
          ),
        ),
      ),
    );

    expect(find.text('Open Ride Offer'), findsOneWidget);
    expect(find.text('Submit Offer'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);

    await tester.tap(find.text('Submit Offer'));
    expect(submitted, isTrue);
  });

  testWidgets('shows a pending offer without another submission action', (
    tester,
  ) async {
    final submittedSession = {
      ...session,
      'offers': [
        {'status': 'pending', 'proposed_fare': 27500},
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: PoolBidCard(
            bid: submittedSession,
            submittingBidId: null,
            onDecline: null,
            onSubmitOffer: null,
          ),
        ),
      ),
    );

    expect(find.text('Offer Submitted'), findsOneWidget);
    expect(find.text('₱275.00'), findsOneWidget);
    expect(
      find.text('Waiting for the passenger to accept your offer.'),
      findsOneWidget,
    );
    expect(find.text('Submit Offer'), findsNothing);
    expect(find.text('Decline'), findsNothing);
  });

  testWidgets('ticks countdown once per second while active', (tester) async {
    final tickingSession = {
      ...session,
      'expires_at': DateTime.now()
          .add(const Duration(seconds: 45))
          .toIso8601String(),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: PoolBidCard(
            bid: tickingSession,
            submittingBidId: null,
            onDecline: () {},
            onSubmitOffer: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('request-countdown-session-1')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}
