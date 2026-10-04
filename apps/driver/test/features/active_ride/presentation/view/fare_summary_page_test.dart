import 'package:driver/src/features/active_ride/presentation/view/fare_summary_page.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dashboard_stats.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dispatch_snapshot.dart';
import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class const _NoOpDashboardRepository() implements DashboardRepository {
  @override
  Future<Result<bool, Failure>> getPersistedOnlineStatus() async =>
      const Ok(false);

  @override
  Future<Result<DateTime?, Failure>> getPersistedOnlineSince() async =>
      const Ok(null);

  @override
  Future<Result<void, Failure>> updateOnlineStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  }) async => const Ok(null);

  @override
  Future<Result<DriverDashboardStats, Failure>> getDashboardStats() async =>
      const Ok(DriverDashboardStats(earnings: 0, completedTrips: 0));

  @override
  Future<Result<DriverDispatchSnapshot, Failure>> getDispatchSnapshot({
    bool includeOffers = true,
    int limit = 10,
  }) async => const Ok(DriverDispatchSnapshot(activeTrips: [], rideOffers: []));

  @override
  Future<Result<void, Failure>> submitRideOffer({
    required String sessionId,
    required double farePesos,
  }) async => const Ok(null);

  @override
  Future<Result<RideSnapshot, Failure>> fetchRide(String rideId) async =>
      const Err(ServerFailure());
}

void main() {
  testWidgets('displays trip fares as whole pesos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FareSummaryPage(
          pickup: 'Pickup',
          dropoff: 'Dropoff',
          duration: '5 min',
          distance: 2.5,
          fare: 29.69,
          dashboardCubit: DashboardCubit(
            repository: const _NoOpDashboardRepository(),
          ),
        ),
      ),
    );

    expect(find.text('₱30'), findsOneWidget);
    expect(find.text('₱29.69'), findsNothing);
  });

  testWidgets('lets the driver record an unpaid cash outcome', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FareSummaryPage(
          pickup: 'Pickup',
          dropoff: 'Dropoff',
          duration: '5 min',
          distance: 2.5,
          fare: 29.69,
          dashboardCubit: DashboardCubit(
            repository: const _NoOpDashboardRepository(),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('cash-received-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('cash-change-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cash-outcome-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passenger refused to pay').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cash-received-field')), findsNothing);
    expect(find.byKey(const ValueKey('cash-change-field')), findsNothing);
    expect(find.text('Record unpaid cash'), findsOneWidget);
    expect(find.textContaining('No cash is recorded.'), findsOneWidget);
  });

  testWidgets('requires a cash outcome before leaving the summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FareSummaryPage(
          pickup: 'Pickup',
          dropoff: 'Dropoff',
          duration: '5 min',
          distance: 2.5,
          fare: 29.69,
          dashboardCubit: DashboardCubit(
            repository: const _NoOpDashboardRepository(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('cash-summary-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Cash outcome required'), findsOneWidget);
    expect(find.text('Continue recording'), findsOneWidget);
    expect(find.text('Cash collection'), findsOneWidget);

    await tester.tap(find.text('Continue recording'));
    await tester.pumpAndSettle();

    expect(find.text('Cash outcome required'), findsNothing);
    expect(find.text('Cash collection'), findsOneWidget);
  });
}
