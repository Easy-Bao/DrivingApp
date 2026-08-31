import 'package:bloc_test/bloc_test.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/earnings/earnings_cubit.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/earnings/earnings_state.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/performance/driver_performance_cubit.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/performance/driver_performance_state.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/trip_history/trip_history_cubit.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/trip_history/trip_history_state.dart';
import 'package:driver_app/src/features/activity/domain/entities/driver_activity_stats.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foundation/foundation.dart';

class _MockActivityRepository extends Mock
    implements IDriverActivityRepository {}

class _MockSessionService extends Mock implements DriverSessionStore {}

void main() {
  late _MockActivityRepository repository;
  late _MockSessionService sessionService;

  setUp(() {
    repository = _MockActivityRepository();
    sessionService = _MockSessionService();
    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-1');
  });

  blocTest<DriverEarningsCubit, DriverEarningsState>(
    'loads earnings through the repository boundary',
    build: () {
      when(
        () => repository.fetchEarningsSummary('driver-1'),
      ).thenAnswer((_) async => const Right({'this_week': {}}));
      return DriverEarningsCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const DriverEarningsState(isLoading: true),
      isA<DriverEarningsState>()
          .having((state) => state.isLoading, 'isLoading', isFalse)
          .having((state) => state.data, 'data', {'this_week': {}}),
    ],
  );

  blocTest<DriverPerformanceCubit, DriverPerformanceState>(
    'loads performance statistics independently from profile data',
    build: () {
      when(() => repository.fetchStats('driver-1')).thenAnswer(
        (_) async => const Right(
          DriverActivityStats(
            todayEarningsCentavos: 2817,
            todayCompletedTrips: 1,
            totalTrips: 6,
            completedTrips: 5,
            totalEarningsCentavos: 14085,
            averageRating: 4.8,
          ),
        ),
      );
      return DriverPerformanceCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<DriverPerformanceLoading>(),
      isA<DriverPerformanceLoaded>()
          .having((state) => state.isLoading, 'isLoading', isFalse)
          .having((state) => state.stats.completedTrips, 'completed trips', 5),
    ],
  );

  blocTest<DriverTripHistoryCubit, DriverTripHistoryState>(
    'merges paginated history without duplicating a trip',
    build: () {
      when(
        () => repository.fetchTripHistory('driver-1', limit: 25, offset: 0),
      ).thenAnswer(
        (_) async => const Right(
          OffsetPage(
            items: [
              {'id': 1, 'status': 'completed'},
            ],
            hasMore: true,
            nextOffset: 25,
          ),
        ),
      );
      when(
        () => repository.fetchTripHistory('driver-1', limit: 25, offset: 25),
      ).thenAnswer(
        (_) async => const Right(
          OffsetPage(
            items: [
              {'id': 1, 'status': 'completed'},
              {'id': 2, 'status': 'completed'},
            ],
            hasMore: false,
            nextOffset: null,
          ),
        ),
      );
      return DriverTripHistoryCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    expect: () => [
      const DriverTripHistoryState(isLoading: true),
      isA<DriverTripHistoryState>()
          .having((state) => state.trips, 'first page', hasLength(1))
          .having((state) => state.hasMore, 'has more', isTrue),
      isA<DriverTripHistoryState>().having(
        (state) => state.isLoadingMore,
        'loading more',
        isTrue,
      ),
      isA<DriverTripHistoryState>()
          .having((state) => state.trips, 'merged trips', hasLength(2))
          .having((state) => state.hasMore, 'has more', isFalse),
    ],
  );

  blocTest<DriverTripHistoryCubit, DriverTripHistoryState>(
    'keeps request failures separate from an empty history',
    build: () {
      when(
        () => repository.fetchTripHistory('driver-1', limit: 25, offset: 0),
      ).thenAnswer(
        (_) async =>
            const Left(ServerFailure('pq: relation "rides" does not exist')),
      );
      return DriverTripHistoryCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const DriverTripHistoryState(isLoading: true),
      isA<DriverTripHistoryState>()
          .having((state) => state.trips, 'trips', isEmpty)
          .having(
            (state) => state.errorMessage,
            'safe error message',
            'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
          ),
    ],
  );

  blocTest<DriverTripHistoryCubit, DriverTripHistoryState>(
    'preserves loaded trips when a refresh fails',
    build: () {
      var requestCount = 0;
      when(
        () => repository.fetchTripHistory('driver-1', limit: 25, offset: 0),
      ).thenAnswer((_) async {
        requestCount++;
        if (requestCount == 1) {
          return const Right(
            OffsetPage(
              items: [
                {'id': 1, 'status': 'completed'},
              ],
              hasMore: true,
              nextOffset: 25,
            ),
          );
        }
        return const Left(ServerFailure('database connection refused'));
      });
      return DriverTripHistoryCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    expect: () => [
      const DriverTripHistoryState(isLoading: true),
      isA<DriverTripHistoryState>()
          .having((state) => state.trips, 'loaded trips', hasLength(1))
          .having((state) => state.hasMore, 'pagination', isTrue),
      isA<DriverTripHistoryState>()
          .having((state) => state.isLoading, 'refresh loading', isTrue)
          .having(
            (state) => state.trips,
            'preserved during refresh',
            hasLength(1),
          )
          .having((state) => state.hasMore, 'preserved pagination', isTrue),
      isA<DriverTripHistoryState>()
          .having((state) => state.isLoading, 'refresh finished', isFalse)
          .having((state) => state.trips, 'preserved trips', hasLength(1))
          .having(
            (state) => state.errorMessage,
            'safe refresh error',
            'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
          ),
    ],
  );
}
