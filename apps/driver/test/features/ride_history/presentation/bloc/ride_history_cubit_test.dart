import 'package:bloc_test/bloc_test.dart';
import 'package:driver/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_cubit.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_state.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockRideHistoryRepository extends Mock
    implements RideHistoryRepository {}

class _MockSessionService extends Mock implements SessionStore {}

void main() {
  late _MockRideHistoryRepository repository;
  late _MockSessionService sessionService;

  setUp(() {
    repository = _MockRideHistoryRepository();
    sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
  });

  blocTest<TripHistoryCubit, TripHistoryState>(
    'merges paginated history without duplicating a trip',
    build: () {
      when(
        () => repository.fetchTripHistory(
          'driver-1',
          limit: 25,
          offset: 0,
          cursor: '',
        ),
      ).thenAnswer(
        (_) async => const Ok(
          OffsetPage(
            items: [
              {'id': 1, 'status': 'completed'},
            ],
            hasMore: true,
            nextOffset: 25,
          ),
        ),
      );
      when(() => repository.fetchTripHistory('driver-1', limit: 25, offset: 25))
          .thenAnswer(
            (_) async => const Ok(
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
      return TripHistoryCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    expect: () => [
      const TripHistoryState(isLoading: true),
      isA<TripHistoryState>()
          .having((state) => state.trips, 'first page', hasLength(1))
          .having((state) => state.hasMore, 'has more', isTrue),
      isA<TripHistoryState>().having(
        (state) => state.isLoadingMore,
        'loading more',
        isTrue,
      ),
      isA<TripHistoryState>()
          .having((state) => state.trips, 'merged trips', hasLength(2))
          .having((state) => state.hasMore, 'has more', isFalse),
    ],
  );

  blocTest<TripHistoryCubit, TripHistoryState>(
    'keeps request failures separate from an empty history',
    build: () {
      when(
        () => repository.fetchTripHistory(
          'driver-1',
          limit: 25,
          offset: 0,
          cursor: '',
        ),
      ).thenAnswer(
        (_) async =>
            const Err(ServerFailure('pq: relation "rides" does not exist')),
      );
      return TripHistoryCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const TripHistoryState(isLoading: true),
      isA<TripHistoryState>()
          .having((state) => state.trips, 'trips', isEmpty)
          .having(
            (state) => state.errorMessage,
            'safe error message',
            'Something went wrong. Try again.',
          ),
    ],
  );

  blocTest<TripHistoryCubit, TripHistoryState>(
    'preserves loaded trips when a refresh fails',
    build: () {
      var requestCount = 0;
      when(
        () => repository.fetchTripHistory(
          'driver-1',
          limit: 25,
          offset: 0,
          cursor: '',
        ),
      ).thenAnswer((_) async {
        requestCount++;
        if (requestCount == 1) {
          return const Ok(
            OffsetPage(
              items: [
                {'id': 1, 'status': 'completed'},
              ],
              hasMore: true,
              nextOffset: 25,
            ),
          );
        }
        return const Err(ServerFailure('database connection refused'));
      });
      return TripHistoryCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    expect: () => [
      const TripHistoryState(isLoading: true),
      isA<TripHistoryState>()
          .having((state) => state.trips, 'loaded trips', hasLength(1))
          .having((state) => state.hasMore, 'pagination', isTrue),
      isA<TripHistoryState>()
          .having((state) => state.isLoading, 'refresh loading', isTrue)
          .having(
            (state) => state.trips,
            'preserved during refresh',
            hasLength(1),
          )
          .having((state) => state.hasMore, 'preserved pagination', isTrue),
      isA<TripHistoryState>()
          .having((state) => state.isLoading, 'refresh finished', isFalse)
          .having((state) => state.trips, 'preserved trips', hasLength(1))
          .having(
            (state) => state.errorMessage,
            'safe refresh error',
            'Something went wrong. Try again.',
          ),
    ],
  );
}
