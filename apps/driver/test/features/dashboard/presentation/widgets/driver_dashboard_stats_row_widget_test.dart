import 'package:driver/src/features/dashboard/presentation/widgets/driver_dashboard/driver_dashboard_stats_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  testWidgets('renders one inline dashboard error with one retry action', (
    tester,
  ) async {
    var retryCount = 0;
    const message = 'Unable to reach driver activity services.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverDashboardStatsRowWidget(
            isLoadingStats: false,
            earnings: 0,
            completedTrips: 0,
            errorMessage: message,
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    expect(find.text(message), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));

    expect(retryCount, 1);
  });

  testWidgets('shows a progress status before stats exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverDashboardStatsRowWidget(
            isLoadingStats: true,
            earnings: 0,
            completedTrips: 0,
            errorMessage: 'stale error',
          ),
        ),
      ),
    );

    expect(find.text('stale error'), findsNothing);
    expect(find.text("Today's Net Earnings"), findsNothing);
    expect(find.byType(Bone), findsNothing);
    expect(find.text("Loading today's activity"), findsOneWidget);
  });

  testWidgets('keeps the stats skeleton during a refresh with existing data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverDashboardStatsRowWidget(
            isLoadingStats: true,
            hasExistingStats: true,
            earnings: 385.5,
            completedTrips: 7,
          ),
        ),
      ),
    );

    expect(find.text("Today's Net Earnings"), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('driver-dashboard-stats-skeleton')),
      findsOneWidget,
    );
  });
}
