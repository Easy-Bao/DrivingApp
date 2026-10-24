import 'package:design_system/design_system.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/performance/presentation/bloc/driver_performance_cubit.dart';
import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:driver/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver/src/features/performance/presentation/view/driver_performance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockPerformanceRepository extends Mock
    implements PerformanceRepository {}

class _MockSessionService extends Mock implements SessionStore {}

void main() {
  testWidgets('shows balanced driver performance metrics at compact width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MockPerformanceRepository();
    final sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
    when(() => repository.fetchStats('driver-1')).thenAnswer(
      (_) async => const Ok(
        PerformanceStats(
          todayEarningsAmount: 1245050,
          todayCompletedTrips: 18,
          totalTrips: 20,
          completedTrips: 18,
          totalEarningsAmount: 1245050,
          averageRating: 4.8,
          standing: DriverStanding(
            settledTrips: 20,
            driverFaultCancellations: 1,
            passengerFaultCancellations: 1,
            completionRatePercent: 90,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider<PerformanceCubit>(
          create: (_) => PerformanceCubit(
            repository: repository,
            sessionService: sessionService,
          )..load(),
          child: PerformancePage(onBack: () {}, onRefresh: () async {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('90% trip completion'), findsOneWidget);
    expect(find.text('Completed trips'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Total trips'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Lifetime earnings'), findsOneWidget);
    expect(find.text('Rating breakdown'), findsNothing);
    expect(find.text('Pending review: 0'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.text('Trip reliability'), findsOneWidget);
    expect(find.text('Driver-attributed cancellations'), findsOneWidget);
    expect(find.text('Passenger attributed: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('keeps real rating details usable with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _MockPerformanceRepository();
    final sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
    when(() => repository.fetchStats('driver-1')).thenAnswer(
      (_) async => const Ok(
        PerformanceStats(
          todayEarningsAmount: 10000,
          todayCompletedTrips: 1,
          totalTrips: 2,
          completedTrips: 1,
          totalEarningsAmount: 10000,
          averageRating: 5,
          ratingDistribution: [0, 0, 0, 0, 1],
          standing: DriverStanding(
            settledTrips: 2,
            completionRatePercent: 50,
            pendingReviewCancellations: 1,
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: BlocProvider(
          create: (_) => PerformanceCubit(
            repository: repository,
            sessionService: sessionService,
          )..load(),
          child: PerformancePage(onBack: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Pending review: 1'), 200);
    expect(find.text('Pending review: 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rating breakdown'), 200);
    await tester.pumpAndSettle();
    expect(find.text('5 star'), findsNothing);
    await tester.tap(find.text('Rating breakdown'));
    await tester.pumpAndSettle();
    expect(find.text('5 star'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
