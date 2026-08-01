import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/CoreModels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/Features/Home/Presentation/Bloc/HomeCubit.dart';
import 'package:passenger_app/src/Features/Home/Presentation/Bloc/HomeState.dart';

// Mock Repositories

class MockHomeRepo extends Mock implements IPassengerHomeRepository {}

// Helper Factory Methods

HomeCubit _makeCubit(PassengerHomeRepository repo) =>
    HomeCubit(repository: repo);

// Unit Tests

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
      expect: () => [
        const HomeState(currentAddress: 'SM City Pagadian'),
      ],
    );
  });
}
