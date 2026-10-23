import 'package:design_system/design_system.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_cubit.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_state.dart';
import 'package:driver/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:driver/src/features/ride_history/presentation/view/driver_trip_history_page.dart';
import 'package:flutter/material.dart';
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
    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
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
}
