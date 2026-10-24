import 'package:driver/src/features/dashboard/presentation/widgets/driver_dashboard_stats_row.dart';
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
          body: DashboardStatsRow(
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

  testWidgets('shows an inline retry when initial statistics fail', (
    tester,
  ) async {
    var retryCount = 0;
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardStatsRow(
            isLoadingStats: false,
            earnings: 0,
            completedTrips: 0,
            hasError: true,
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    expect(find.text('—'), findsNWidgets(2));
    expect(find.text("Today's stats are unavailable."), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('driver-dashboard-stats-retry')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('driver-dashboard-stats-retry')),
    );
    expect(retryCount, 1);
  });

  testWidgets('keeps loaded values visible when statistics refresh fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardStatsRow(
            isLoadingStats: false,
            hasExistingStats: true,
            earnings: 385.5,
            completedTrips: 7,
            hasError: true,
          ),
        ),
      ),
    );

    expect(find.text('₱385.50'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Showing last loaded stats.'), findsOneWidget);
  });

  testWidgets('shows skeleton stats before data exists', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardStatsRow(
            isLoadingStats: true,
            earnings: 0,
            completedTrips: 0,
          ),
        ),
      ),
    );

    expect(find.text('stale error'), findsNothing);
    expect(find.text("Today's Net Earnings"), findsNothing);
    expect(find.byWidgetPredicate((widget) => widget is Bone), findsWidgets);
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
          body: DashboardStatsRow(
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

  testWidgets('keeps existing stats visible during a background refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardStatsRow(
            isLoadingStats: true,
            hasExistingStats: true,
            earnings: 385.5,
            completedTrips: 7,
          ),
        ),
      ),
    );

    expect(find.text("Today's Net Earnings"), findsOneWidget);
    expect(find.text('₱385.50'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('driver-dashboard-stats-skeleton')),
      findsNothing,
    );
    expect(find.byWidgetPredicate((widget) => widget is Bone), findsNothing);
  });

  testWidgets('renders stats row on narrow 360px screen without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardStatsRow(
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

  testWidgets('wraps stat labels on compact screens with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: const Scaffold(
            body: DashboardStatsRow(
              isLoadingStats: false,
              earnings: 12500.5,
              completedTrips: 18,
            ),
          ),
        ),
      ),
    );

    expect(find.text("Today's Net Earnings"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
