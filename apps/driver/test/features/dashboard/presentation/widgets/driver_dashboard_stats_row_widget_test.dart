import 'package:driver/src/features/dashboard/presentation/widgets/driver_dashboard/driver_dashboard_stats_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  testWidgets('keeps dashboard stats in place without an inline error card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverDashboardStatsRowWidget(
            isLoadingStats: false,
            earnings: 0,
            completedTrips: 0,
          ),
        ),
      ),
    );

    expect(find.text("Today's Net Earnings"), findsOneWidget);
    expect(find.text('Trips Today'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('shows skeleton stats before data exists', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverDashboardStatsRowWidget(
            isLoadingStats: true,
            earnings: 0,
            completedTrips: 0,
          ),
        ),
      ),
    );

    expect(find.text('stale error'), findsNothing);
    expect(find.text("Today's Net Earnings"), findsNothing);
    expect(find.byType(Bone), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('keeps the initial skeleton inside narrow stat cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverDashboardStatsRowWidget(
            isLoadingStats: true,
            earnings: 0,
            completedTrips: 0,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('driver-dashboard-stats-loading')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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

  testWidgets('renders stats row on narrow 360px screen without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverDashboardStatsRowWidget(
            isLoadingStats: false,
            hasExistingStats: true,
            earnings: 12500.5,
            completedTrips: 18,
          ),
        ),
      ),
    );

    expect(find.text("Today's Net Earnings"), findsOneWidget);
    expect(find.text('Trips Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
