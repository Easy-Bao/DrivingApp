import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/home/view/widgets/recent_activity_empty_state_widget.dart';

void main() {
  testWidgets('explains that activity is unavailable in guest mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecentActivityEmptyStateWidget(isGuest: true)),
      ),
    );

    expect(find.text('Guest mode'), findsOneWidget);
    expect(find.text('Sign in to view your recent trips.'), findsOneWidget);
    expect(find.text('No recent trips yet'), findsNothing);
  });

  testWidgets('keeps the empty-history copy for signed-in passengers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecentActivityEmptyStateWidget(isGuest: false)),
      ),
    );

    expect(find.text('No recent trips yet'), findsOneWidget);
    expect(
      find.text('Your recent ride history will appear here.'),
      findsOneWidget,
    );
    expect(find.text('Guest mode'), findsNothing);
  });
}
