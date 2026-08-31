import 'package:driver_app/src/app/theme/app_theme.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/performance/driver_performance_cubit.dart';
import 'package:driver_app/src/features/activity/domain/entities/driver_activity_stats.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/presentation/view/driver_performance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockActivityRepository extends Mock
    implements IDriverActivityRepository {}

class _MockSessionService extends Mock implements DriverSessionStore {}

void main() {
  testWidgets('shows balanced driver performance metrics at compact width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MockActivityRepository();
    final sessionService = _MockSessionService();
    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-1');
    when(() => repository.fetchStats('driver-1')).thenAnswer(
      (_) async => const Right(
        DriverActivityStats(
          todayEarningsCentavos: 1245050,
          todayCompletedTrips: 18,
          totalTrips: 20,
          completedTrips: 18,
          totalEarningsCentavos: 1245050,
          averageRating: 4.8,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: BlocProvider<DriverPerformanceCubit>(
          create: (_) => DriverPerformanceCubit(
            repository: repository,
            sessionService: sessionService,
          )..load(),
          child: DriverPerformancePage(onBack: () {}, onRefresh: () async {}),
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
    expect(tester.takeException(), isNull);
  });
}
