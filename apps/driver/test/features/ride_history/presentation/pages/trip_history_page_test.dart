import 'package:design_system/design_system.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_cubit.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_state.dart';
import 'package:driver/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:driver/src/features/ride_history/presentation/pages/trip_history_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foundation/foundation.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _MockRideHistoryRepository extends Mock
    implements RideHistoryRepository {}

class _MockSessionService extends Mock implements SessionStore {}

void main() {
  testWidgets('shows a retryable error instead of an empty history state', (
    tester,
  ) async {
    final repository = _MockRideHistoryRepository();
    final sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
    when(
      () => repository.fetchTripHistory(
        'driver-1',
        limit: 25,
        offset: 0,
        cursor: '',
      ),
    ).thenAnswer(
      (_) async =>
          const Err(ServerFailure('backend query details must stay internal')),
    );

    final cubit = TripHistoryCubit(
      repository: repository,
      sessionService: sessionService,
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider.value(value: cubit, child: const TripHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load trips'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('No trip history found'), findsNothing);
    expect(find.text('backend query details must stay internal'), findsNothing);
    expect(
      find.text('The server could not complete your request. Try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await cubit.close();
  });

  testWidgets('keeps loaded trips readable during a refresh', (tester) async {
    final repository = _MockRideHistoryRepository();
    final sessionService = _MockSessionService();
    final cubit =
        TripHistoryCubit(repository: repository, sessionService: sessionService)
          ..emit(
            const TripHistoryState(
              isLoading: true,
              trips: [
                {
                  'id': 42,
                  'status': 'completed',
                  'created_at': '2026-08-19T10:00:00Z',
                  'pickup_name': 'Mountain View',
                  'dropoff_name': 'Vista Slope',

                  'fare_amount': 2973,
                  'distance_km': 1.8,
                },
              ],
            ),
          );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider.value(value: cubit, child: const TripHistoryPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Mountain View'), findsOneWidget);
    expect(find.text('Vista Slope'), findsOneWidget);
    expect(find.byType(Skeletonizer), findsNothing);
    expect(tester.takeException(), isNull);

    await cubit.close();
  });

  testWidgets(
    'filters trips inline with gliding indicator and disables platform splashes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _MockRideHistoryRepository();
      final sessionService = _MockSessionService();
      final cubit =
          TripHistoryCubit(
            repository: repository,
            sessionService: sessionService,
          )..emit(
            const TripHistoryState(
              trips: [
                {
                  'id': 42,
                  'status': 'completed',
                  'created_at': '2026-08-19T10:00:00Z',
                  'pickup_name': 'Mountain View',
                  'dropoff_name': 'Vista Slope',
                  'fare_amount': 2973,
                  'distance_km': 1.8,
                },
                {
                  'id': 43,
                  'status': 'canceled',
                  'created_at': '2026-08-19T11:00:00Z',
                  'pickup_name': 'Central Station',
                  'dropoff_name': 'Harbor Pier',
                  'fare_amount': 1500,
                  'distance_km': 1.2,
                },
              ],
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: BlocProvider.value(
            value: cubit,
            child: const TripHistoryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mountain View'), findsOneWidget);
      expect(find.text('Central Station'), findsOneWidget);

      final cancelledTab = tester.widget<InkWell>(
        find.byKey(const ValueKey<String>('driver-trips-filter-cancelled')),
      );
      expect(cancelledTab.enableFeedback, isFalse);
      expect(cancelledTab.splashFactory, NoSplash.splashFactory);

      await tester.tap(
        find.byKey(const ValueKey<String>('driver-trips-filter-cancelled')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mountain View'), findsNothing);
      expect(find.text('Central Station'), findsOneWidget);

      final rowInkWell = tester.widget<InkWell>(
        find.byKey(const ValueKey<String>('driver-trip-row-43')),
      );
      expect(rowInkWell.enableFeedback, isFalse);
      expect(rowInkWell.splashFactory, NoSplash.splashFactory);
      expect(tester.takeException(), isNull);

      await cubit.close();
    },
  );
}
