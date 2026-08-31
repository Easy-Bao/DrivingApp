import 'package:ride/ride.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/activity/presentation/bloc/activity/activity_bloc.dart';
import 'package:passenger_app/src/features/activity/domain/entities/activity_overview.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/i_activity_repository.dart';
import 'package:shared_core/shared_core.dart';

class MockActivityRepo extends Mock implements IActivityRepository {}

ActivityBloc _makeCubit(IActivityRepository repo) =>
    ActivityBloc(repository: repo);

void main() {
  late MockActivityRepo repo;

  setUp(() => repo = MockActivityRepo());

  group('ActivityBloc — initial state', () {
    test('starts as ActivityInitial', () async {
      final bloc = _makeCubit(repo);
      expect(bloc.state, isA<ActivityInitial>());
      await bloc.close();
    });
  });

  group('ActivityBloc — LoadActivityEvent', () {
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

    blocTest<ActivityBloc, ActivityState>(
      'emits [Loading, Loaded] with correctly segregated past and upcoming rides',
      build: () {
        when(
          () => repo.fetchActivityOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer(
          (_) async => const Right(
            ActivityOverview(
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
      act: (bloc) => bloc.add(const LoadActivityEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<ActivityLoading>().having(
          (state) => state.existingRideCount,
          'existing ride count',
          0,
        ),
        isA<ActivityLoaded>()
            .having((s) => s.past.length, 'past count', 1)
            .having((s) => s.past.first.id, 'past first id', 'ride-1')
            .having((s) => s.upcoming.length, 'upcoming count', 1)
            .having((s) => s.upcoming.first.id, 'upcoming first id', 'ride-2'),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'emits [Loading, ActivityError] on repository failure',
      build: () {
        when(
          () => repo.fetchActivityOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Left(ServerFailure('network error')));
        return _makeCubit(repo);
      },
      act: (bloc) => bloc.add(const LoadActivityEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<ActivityLoading>().having(
          (state) => state.existingRideCount,
          'existing ride count',
          0,
        ),
        isA<ActivityError>().having(
          (s) => s.message,
          'error message',
          'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
        ),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'emits ActivityLoaded with empty lists when repository returns no rides',
      build: () {
        when(
          () => repo.fetchActivityOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer(
          (_) async => const Right(
            ActivityOverview(
              rides: OffsetPage(items: [], hasMore: false, nextOffset: null),
              weeklyFareCentavos: 0,
              weeklyRideCount: 0,
            ),
          ),
        );
        return _makeCubit(repo);
      },
      act: (bloc) => bloc.add(const LoadActivityEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<ActivityLoading>().having(
          (state) => state.existingRideCount,
          'existing ride count',
          0,
        ),
        isA<ActivityLoaded>()
            .having((s) => s.past, 'past', isEmpty)
            .having((s) => s.upcoming, 'upcoming', isEmpty),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'reports existing rides while refreshing populated activity',
      build: () {
        when(
          () => repo.fetchActivityOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer(
          (_) async => const Right(
            ActivityOverview(
              rides: OffsetPage(items: [], hasMore: false, nextOffset: null),
              weeklyFareCentavos: 0,
              weeklyRideCount: 0,
            ),
          ),
        );
        return _makeCubit(repo);
      },
      seed: () => const ActivityLoaded(
        past: [completedRide],
        upcoming: [requestedRide],
      ),
      act: (bloc) => bloc.add(const LoadActivityEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<ActivityLoading>().having(
          (state) => state.existingRideCount,
          'existing ride count',
          2,
        ),
        isA<ActivityLoaded>()
            .having((state) => state.past, 'past', isEmpty)
            .having((state) => state.upcoming, 'upcoming', isEmpty),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
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
      seed: () => const ActivityLoaded(
        past: [completedRide],
        upcoming: [],
        hasMore: true,
        nextOffset: 25,
      ),
      act: (bloc) =>
          bloc.add(const LoadMoreActivityEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<ActivityLoaded>().having(
          (state) => state.isLoadingMore,
          'loading more',
          isTrue,
        ),
        isA<ActivityLoaded>()
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

  group('ActivityBloc — RefreshActivityEvent', () {
    blocTest<ActivityBloc, ActivityState>(
      'refreshes without emitting ActivityLoading first',
      build: () {
        when(
          () => repo.fetchActivityOverview(any(), limit: any(named: 'limit')),
        ).thenAnswer(
          (_) async => const Right(
            ActivityOverview(
              rides: OffsetPage(items: [], hasMore: false, nextOffset: null),
              weeklyFareCentavos: 0,
              weeklyRideCount: 0,
            ),
          ),
        );
        return _makeCubit(repo);
      },
      act: (bloc) =>
          bloc.add(const RefreshActivityEvent(passengerId: 'pass-1')),
      expect: () => [isA<ActivityLoaded>()],
    );
  });
}
