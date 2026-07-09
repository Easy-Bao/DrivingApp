import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/passenger_home_cubit.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/passenger_home_state.dart';

// Mock Repositories

class MockHomeRepo extends Mock implements PassengerHomeRepository {}

// Helper Factory Methods

PassengerHomeCubit _makeCubit(PassengerHomeRepository repo) =>
    PassengerHomeCubit(repository: repo);

// Unit Tests

void main() {
  late MockHomeRepo repo;

  setUp(() => repo = MockHomeRepo());

  group('PassengerHomeCubit — initial state', () {
    test('starts with empty address and no locations', () async {
      final cubit = _makeCubit(repo);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.currentAddress, '');
      expect(cubit.state.recentLocations, isEmpty);
      await cubit.close();
    });
  });

  group('PassengerHomeCubit — loadHomeData()', () {
    const resolvedAddress = 'Tuburan, Pagadian';
    final mockLocations = [
      {'title': 'Plaza Luz', 'subtitle': 'San Francisco', 'lat': 7.8275, 'lng': 123.4365},
    ];

    blocTest<PassengerHomeCubit, PassengerHomeState>(
      'emits [loading=true, loaded with address+locations] on success',
      build: () {
        when(
          () => repo.resolveAddress(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => resolvedAddress);
        when(() => repo.getRecentLocations())
            .thenAnswer((_) async => mockLocations);
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadHomeData(lat: 7.828282, lng: 123.434343),
      expect: () => [
        const PassengerHomeState(isLoading: true),
        PassengerHomeState(
          isLoading: false,
          currentAddress: resolvedAddress,
          recentLocations: mockLocations,
        ),
      ],
    );

    blocTest<PassengerHomeCubit, PassengerHomeState>(
      'emits [loading=true, loading=false] gracefully on error',
      build: () {
        when(
          () => repo.resolveAddress(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenThrow(Exception('geocode error'));
        when(() => repo.getRecentLocations())
            .thenThrow(Exception('network error'));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadHomeData(lat: 7.828282, lng: 123.434343),
      expect: () => [
        const PassengerHomeState(isLoading: true),
        const PassengerHomeState(isLoading: false),
      ],
    );
  });

  group('PassengerHomeCubit — updateAddress()', () {
    blocTest<PassengerHomeCubit, PassengerHomeState>(
      'emits updated address without touching other state',
      build: () => _makeCubit(repo),
      act: (cubit) => cubit.updateAddress('SM City Pagadian'),
      expect: () => [
        const PassengerHomeState(currentAddress: 'SM City Pagadian'),
      ],
    );
  });
}
