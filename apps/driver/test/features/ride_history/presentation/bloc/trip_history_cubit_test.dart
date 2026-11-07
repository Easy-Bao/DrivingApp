import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_cubit.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockRideHistoryRepository extends Mock
    implements RideHistoryRepository {}

class _MockSessionService extends Mock implements SessionStore {}

typedef _Page = Result<OffsetPage<Map<String, dynamic>>, Failure>;

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

  test('refresh supersedes an in-flight pagination response', () async {
    final firstPages = [
      const OffsetPage<Map<String, dynamic>>(
        items: [
          {'id': 1},
        ],
        hasMore: true,
        nextOffset: null,
        nextCursor: 'fresh-boundary',
      ),
      const OffsetPage<Map<String, dynamic>>(
        items: [
          {'id': 2},
        ],
        hasMore: true,
        nextOffset: null,
        nextCursor: 'refreshed-boundary',
      ),
    ];
    var firstPageCalls = 0;
    when(
      () => repository.fetchTripHistory(
        'driver-1',
        limit: 25,
        offset: 0,
        cursor: '',
      ),
    ).thenAnswer((_) async => Ok(firstPages[firstPageCalls++]));
    final stalePage = Completer<_Page>();
    when(
      () => repository.fetchTripHistory(
        'driver-1',
        limit: 25,
        offset: 0,
        cursor: 'fresh-boundary',
      ),
    ).thenAnswer((_) => stalePage.future);

    final cubit = TripHistoryCubit(
      repository: repository,
      sessionService: sessionService,
    );
    await cubit.load();
    final pagination = cubit.loadMore();
    await Future<void>.delayed(Duration.zero);
    await cubit.load();

    stalePage.complete(
      const Ok(
        OffsetPage<Map<String, dynamic>>(
          items: [
            {'id': 99},
          ],
          hasMore: false,
          nextOffset: null,
        ),
      ),
    );
    await pagination;

    expect(cubit.state.trips.map((trip) => trip['id']), [2]);
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.nextOffset, isNull);
    expect(cubit.state.nextCursor, 'refreshed-boundary');
    expect(cubit.state.isLoadingMore, isFalse);

    await cubit.close();
  });
}
