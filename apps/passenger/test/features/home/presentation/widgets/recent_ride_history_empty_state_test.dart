import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_empty_state.dart';

void main() {
  testWidgets('explains that activity is unavailable in guest mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecentRideHistoryEmptyState(isGuest: true)),
      ),
    );

    expect(find.text('Your trips, in one place'), findsOneWidget);
    expect(
      find.text(
        'Sign in or create an account to book rides and keep your trip history here.',
      ),
      findsOneWidget,
    );
    expect(find.text('No recent trips yet'), findsNothing);
  });

  testWidgets('keeps the empty-history copy for signed-in passengers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecentRideHistoryEmptyState(isGuest: false)),
      ),
    );

    expect(find.text('No recent trips yet'), findsOneWidget);
    expect(
      find.text('Your recent ride history will appear here.'),
      findsOneWidget,
    );
    expect(find.text('Your trips, in one place'), findsNothing);
  });
}
