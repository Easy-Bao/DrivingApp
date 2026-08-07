import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/home/bloc/home/home_cubit.dart';
import 'package:passenger_app/src/features/home/bloc/home/home_state.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_passenger_home_repository.dart';
import 'package:shared_core/shared_core.dart';

class MockHomeRepo extends Mock implements IPassengerHomeRepository {}

HomeCubit _makeCubit(IPassengerHomeRepository repo) =>
    HomeCubit(repository: repo);

void main() {
  late MockHomeRepo repo;

  setUp(() => repo = MockHomeRepo());

  group('HomeCubit — initial state', () {
    test('starts with empty address and no locations', () async {
      final cubit = _makeCubit(repo);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.currentAddress, '');
      expect(cubit.state.recentLocations, isEmpty);
      await cubit.close();
    });
  });

  group('HomeCubit — loadHomeData()', () {
    const resolvedAddress = 'Tuburan, Pagadian';
    final mockLocations = [
      {
        'title': 'Plaza Luz',
        'subtitle': 'San Francisco',
        'lat': 7.8275,
        'lng': 123.4365,
      },
    ];

    blocTest<HomeCubit, HomeState>(
      'emits [loading=true, loaded with address+locations] on success',
      build: () {
        when(
          () => repo.resolveAddress(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right(resolvedAddress));
        when(
          () => repo.getRecentLocations(),
        ).thenAnswer((_) async => Right(mockLocations));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadHomeData(lat: 7.828282, lng: 123.434343),
      expect: () => [
        const HomeState(isLoading: true),
        HomeState(
          isLoading: false,
          currentAddress: resolvedAddress,
          recentLocations: mockLocations,
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [loading=true, loading=false] gracefully on error',
      build: () {
        when(
          () => repo.resolveAddress(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('geocode error')));
        when(
          () => repo.getRecentLocations(),
        ).thenAnswer((_) async => const Left(ServerFailure('network error')));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadHomeData(lat: 7.828282, lng: 123.434343),
      expect: () => [
        const HomeState(isLoading: true),
        const HomeState(isLoading: false),
      ],
    );
  });

  group('HomeCubit — updateAddress()', () {
    blocTest<HomeCubit, HomeState>(
      'emits updated address without touching other state',
      build: () => _makeCubit(repo),
      act: (cubit) => cubit.updateAddress('SM City Pagadian'),
      expect: () => [const HomeState(currentAddress: 'SM City Pagadian')],
    );

    blocTest<HomeCubit, HomeState>(
      'clears a stale pickup when location access is lost',
      build: () => _makeCubit(repo)..updateAddress('SM City Pagadian'),
      act: (cubit) => cubit.clearLocation(),
      expect: () => const [HomeState()],
    );
  });
}
