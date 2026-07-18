import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/activity/presentation/bloc/activity_bloc.dart';

class MockActivityRepo extends Mock implements ActivityRepository {}

ActivityBloc _makeCubit(ActivityRepository repo) =>
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
    const completedRide = RideHistoryModel(
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

    const requestedRide = RideHistoryModel(
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
        when(() => repo.fetchRideHistory(any())).thenAnswer(
          (_) async => const Right([completedRide, requestedRide]),
        );
        return _makeCubit(repo);
      },
      act: (bloc) => bloc.add(LoadActivityEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<ActivityLoading>(),
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
        when(() => repo.fetchRideHistory(any())).thenAnswer(
          (_) async => const Left(ServerFailure('network error')),
        );
        return _makeCubit(repo);
      },
      act: (bloc) => bloc.add(LoadActivityEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<ActivityLoading>(),
        isA<ActivityError>().having(
          (s) => s.message,
          'error message',
          'network error',
        ),
      ],
    );

    blocTest<ActivityBloc, ActivityState>(
      'emits ActivityLoaded with empty lists when repository returns no rides',
      build: () {
        when(() => repo.fetchRideHistory(any())).thenAnswer(
          (_) async => const Right([]),
        );
        return _makeCubit(repo);
      },
      act: (bloc) => bloc.add(LoadActivityEvent(passengerId: 'pass-1')),
      expect: () => [
        isA<ActivityLoading>(),
        isA<ActivityLoaded>()
            .having((s) => s.past, 'past', isEmpty)
            .having((s) => s.upcoming, 'upcoming', isEmpty),
      ],
    );
  });

  group('ActivityBloc — RefreshActivityEvent', () {
    blocTest<ActivityBloc, ActivityState>(
      'refreshes without emitting ActivityLoading first',
      build: () {
        when(() => repo.fetchRideHistory(any())).thenAnswer(
          (_) async => const Right([]),
        );
        return _makeCubit(repo);
      },
      act: (bloc) => bloc.add(RefreshActivityEvent(passengerId: 'pass-1')),
      expect: () => [isA<ActivityLoaded>()],
    );
  });
}
