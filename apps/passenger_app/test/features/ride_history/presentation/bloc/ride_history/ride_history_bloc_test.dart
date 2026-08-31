import 'package:passenger_app/src/features/ride_history/ride_history.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger_app/src/features/ride_history/domain/entities/ride_history_overview.dart';
import 'package:passenger_app/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:foundation/foundation.dart';

class MockRideHistoryRepository extends Mock implements RideHistoryRepository {}

RideHistoryBloc _makeCubit(RideHistoryRepository repo) =>
    RideHistoryBloc(repository: repo);

void main() {
  late MockRideHistoryRepository repo;

  setUp(() => repo = MockRideHistoryRepository());

  group('RideHistoryBloc — initial state', () {
    test('starts as RideHistoryInitial', () async {
      final bloc = _makeCubit(repo);
      expect(bloc.state, isA<RideHistoryInitial>());
      await bloc.close();
    });
  });

  group('RideHistoryBloc — LoadRideHistoryEvent', () {
    const completedRide = RideHistory(
      id: 'ride-1',
      pickup: 'SM Pagadian',
      destination: 'Tuburan',
      pickupLat: 7.828,
      pickupLng: 123.434,
      destLat: 7.835,
      destLng: 123.444,
      date: '2025-01-01',
      price: '85.0',
      status: 'completed',
      driverId: 'drv-1',
      driverName: 'Pedro Santos',
      vehiclePlate: 'ABC 1234',
      vehicleType: 'Sedan',
    );

    const requestedRide = RideHistory(
      id: 'ride-2',
      pickup: 'Plaza Luz',
      destination: 'Dao District',
      pickupLat: 7.828,
      pickupLng: 123.434,
      destLat: 7.831,
      destLng: 123.436,
      date: '2025-01-02',
      price: '60.0',
      status: 'requested',
      driverId: 'drv-2',
      driverName: 'Jose Reyes',
      vehiclePlate: 'XYZ 9876',
      vehicleType: 'Bao Bao',
    );

    blocTest<RideHistoryBloc, RideHistoryState>(
      'emits [Loading, Loaded] with correctly segregated past and upcoming rides',
      build: () {
        when(
          () =>
              repo.fetchRideHistoryOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer(
          (_) async => const Right(
            RideHistoryOverview(
              rides: OffsetPage(
                items: [completedRide, requestedRide],
                hasMore: false,
                nextOffset: null,
              ),
              weeklyFareCentavos: 8500,
              weeklyRideCount: 1,
            ),
          ),
        );
        return _makeCubit(repo);
      },
      act: (bloc) =>
          bloc.add(const LoadRideHistoryEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<RideHistoryLoading>().having(
          (state) => state.existingRideCount,
          'existing ride count',
          0,
        ),
        isA<RideHistoryLoaded>()
            .having((s) => s.past.length, 'past count', 1)
            .having((s) => s.past.first.id, 'past first id', 'ride-1')
            .having((s) => s.upcoming.length, 'upcoming count', 1)
            .having((s) => s.upcoming.first.id, 'upcoming first id', 'ride-2'),
      ],
    );

    blocTest<RideHistoryBloc, RideHistoryState>(
      'emits [Loading, RideHistoryError] on repository failure',
      build: () {
        when(
          () =>
              repo.fetchRideHistoryOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Left(ServerFailure('network error')));
        return _makeCubit(repo);
      },
      act: (bloc) =>
          bloc.add(const LoadRideHistoryEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<RideHistoryLoading>().having(
          (state) => state.existingRideCount,
          'existing ride count',
          0,
        ),
        isA<RideHistoryError>().having(
          (s) => s.message,
          'error message',
          'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
        ),
      ],
    );

    blocTest<RideHistoryBloc, RideHistoryState>(
      'emits RideHistoryLoaded with empty lists when repository returns no rides',
      build: () {
        when(
          () =>
              repo.fetchRideHistoryOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer(
          (_) async => const Right(
            RideHistoryOverview(
              rides: OffsetPage(items: [], hasMore: false, nextOffset: null),
              weeklyFareCentavos: 0,
              weeklyRideCount: 0,
            ),
          ),
        );
        return _makeCubit(repo);
      },
      act: (bloc) =>
          bloc.add(const LoadRideHistoryEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<RideHistoryLoading>().having(
          (state) => state.existingRideCount,
          'existing ride count',
          0,
        ),
        isA<RideHistoryLoaded>()
            .having((s) => s.past, 'past', isEmpty)
            .having((s) => s.upcoming, 'upcoming', isEmpty),
      ],
    );

    blocTest<RideHistoryBloc, RideHistoryState>(
      'reports existing rides while refreshing populated activity',
      build: () {
        when(
          () =>
              repo.fetchRideHistoryOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer(
          (_) async => const Right(
            RideHistoryOverview(
              rides: OffsetPage(items: [], hasMore: false, nextOffset: null),
              weeklyFareCentavos: 0,
              weeklyRideCount: 0,
            ),
          ),
        );
        return _makeCubit(repo);
      },
      seed: () => const RideHistoryLoaded(
        past: [completedRide],
        upcoming: [requestedRide],
      ),
      act: (bloc) =>
          bloc.add(const LoadRideHistoryEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<RideHistoryLoading>().having(
          (state) => state.existingRideCount,
          'existing ride count',
          2,
        ),
        isA<RideHistoryLoaded>()
            .having((state) => state.past, 'past', isEmpty)
            .having((state) => state.upcoming, 'upcoming', isEmpty),
      ],
    );

    blocTest<RideHistoryBloc, RideHistoryState>(
      'loads the next page without replacing existing rides',
      build: () {
        when(
          () => repo.fetchRideHistory(
            any(),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer(
          (_) async => const Right(
            OffsetPage(
              items: [requestedRide],
              hasMore: false,
              nextOffset: null,
            ),
          ),
        );
        return _makeCubit(repo);
      },
      seed: () => const RideHistoryLoaded(
        past: [completedRide],
        upcoming: [],
        hasMore: true,
        nextOffset: 25,
      ),
      act: (bloc) =>
          bloc.add(const LoadMoreRideHistoryEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<RideHistoryLoaded>().having(
          (state) => state.isLoadingMore,
          'loading more',
          isTrue,
        ),
        isA<RideHistoryLoaded>()
            .having((state) => state.past.single.id, 'past ride', 'ride-1')
            .having(
              (state) => state.upcoming.single.id,
              'new upcoming ride',
              'ride-2',
            )
            .having((state) => state.hasMore, 'has more', isFalse),
      ],
      verify: (_) {
        verify(
          () => repo.fetchRideHistory('pass-1', limit: 25, offset: 25),
        ).called(1);
      },
    );
  });

  group('RideHistoryBloc — RefreshRideHistoryEvent', () {
    blocTest<RideHistoryBloc, RideHistoryState>(
      'refreshes without emitting RideHistoryLoading first',
      build: () {
        when(
          () =>
              repo.fetchRideHistoryOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer(
          (_) async => const Right(
            RideHistoryOverview(
              rides: OffsetPage(items: [], hasMore: false, nextOffset: null),
              weeklyFareCentavos: 0,
              weeklyRideCount: 0,
            ),
          ),
        );
        return _makeCubit(repo);
      },
      act: (bloc) =>
          bloc.add(const RefreshRideHistoryEvent(passengerId: 'pass-1')),
      expect: () => [isA<RideHistoryLoaded>()],
    );
  });
}
