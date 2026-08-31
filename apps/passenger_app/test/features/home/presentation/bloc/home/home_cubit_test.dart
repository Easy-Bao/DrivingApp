import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/home/home_state.dart';
import 'package:passenger_app/src/features/home/domain/entities/current_location.dart';
import 'package:passenger_app/src/features/home/domain/entities/home_data.dart';
import 'package:passenger_app/src/features/home/domain/entities/recent_location.dart';
import 'package:passenger_app/src/features/home/domain/failures/current_location_failure.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_current_location_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_home_repository.dart';
import 'package:shared_core/shared_core.dart';

class MockHomeRepo extends Mock implements IHomeRepository {}

class MockCurrentLocationRepo extends Mock
    implements ICurrentLocationRepository {}

HomeCubit _makeCubit(
  IHomeRepository repo,
  ICurrentLocationRepository currentLocationRepo,
) =>
    HomeCubit(repository: repo, currentLocationRepository: currentLocationRepo);

void main() {
  late MockHomeRepo repo;
  late MockCurrentLocationRepo currentLocationRepo;

  setUp(() {
    repo = MockHomeRepo();
    currentLocationRepo = MockCurrentLocationRepo();
  });

  group('HomeCubit — initial state', () {
    test('starts with empty address and no locations', () async {
      final cubit = _makeCubit(repo, currentLocationRepo);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.currentAddress, '');
      expect(cubit.state.recentLocations, isEmpty);
      await cubit.close();
    });
  });

  group('HomeCubit — loadHomeData()', () {
    const resolvedAddress = 'Tuburan, Pagadian';
    const mockLocations = <RecentLocation>[
      RecentLocation(
        title: 'Plaza Luz',
        subtitle: 'San Francisco',
        latitude: 7.8275,
        longitude: 123.4365,
      ),
    ];

    blocTest<HomeCubit, HomeState>(
      'emits [loading=true, loaded with address+locations] on success',
      build: () {
        when(
          () => repo.loadHomeData(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async => Right(
            HomeData(
              currentAddress: resolvedAddress,
              recentLocations: mockLocations,
            ),
          ),
        );
        return _makeCubit(repo, currentLocationRepo);
      },
      act: (cubit) => cubit.loadHomeData(lat: 7.828282, lng: 123.434343),
      expect: () => [
        const HomeState(isLoading: true),
        const HomeState(
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
          () => repo.loadHomeData(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('network error')));
        return _makeCubit(repo, currentLocationRepo);
      },
      act: (cubit) => cubit.loadHomeData(lat: 7.828282, lng: 123.434343),
      expect: () => [
        const HomeState(isLoading: true),
        const HomeState(
          isLoading: false,
          locationErrorMessage:
              'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'exposes an error when the server cannot resolve an otherwise successful location response',
      build: () {
        when(
          () => repo.loadHomeData(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(HomeData(currentAddress: '', recentLocations: const [])),
        );
        return _makeCubit(repo, currentLocationRepo);
      },
      act: (cubit) => cubit.loadHomeData(lat: 7.828282, lng: 123.434343),
      expect: () => const [
        HomeState(isLoading: true),
        HomeState(
          locationErrorMessage:
              'Unable to find your pickup location. Tap to retry.',
        ),
      ],
    );

    test(
      'keeps the last pickup address when a later refresh is unresolved',
      () async {
        var requestCount = 0;
        when(
          () => repo.loadHomeData(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async {
          requestCount++;
          return Right(
            HomeData(
              currentAddress: requestCount == 1 ? 'Tuburan, Pagadian' : '',
              recentLocations: const [],
            ),
          );
        });

        final cubit = _makeCubit(repo, currentLocationRepo);
        await cubit.loadHomeData(lat: 7.828282, lng: 123.434343);
        await cubit.loadHomeData(lat: 7.829282, lng: 123.435343);

        expect(requestCount, 2);
        expect(cubit.state.currentAddress, 'Tuburan, Pagadian');
        expect(cubit.state.locationErrorMessage, isEmpty);
        await cubit.close();
      },
    );
  });

  group('HomeCubit — updateAddress()', () {
    blocTest<HomeCubit, HomeState>(
      'emits updated address without touching other state',
      build: () => _makeCubit(repo, currentLocationRepo),
      act: (cubit) => cubit.updateAddress('SM City Pagadian'),
      expect: () => [const HomeState(currentAddress: 'SM City Pagadian')],
    );

    blocTest<HomeCubit, HomeState>(
      'clears a stale pickup when location access is lost',
      build: () =>
          _makeCubit(repo, currentLocationRepo)
            ..updateAddress('SM City Pagadian'),
      act: (cubit) => cubit.clearLocation(),
      expect: () => const [HomeState()],
    );
  });

  group('HomeCubit — location tracking', () {
    blocTest<HomeCubit, HomeState>(
      'uses the position stream when the immediate GPS fix is unavailable',
      setUp: () {
        when(
          () => currentLocationRepo.getCurrentLocation(),
        ).thenAnswer((_) async => const Left(CurrentLocationFailure()));
        when(() => currentLocationRepo.watchCurrentLocation()).thenAnswer(
          (_) => Stream.value(
            const Right(
              CurrentLocation(latitude: 7.828282, longitude: 123.434343),
            ),
          ),
        );
        when(
          () => repo.loadHomeData(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async => Right(
            HomeData(
              currentAddress: 'Tuburan, Pagadian',
              recentLocations: const [],
            ),
          ),
        );
      },
      build: () => _makeCubit(repo, currentLocationRepo),
      act: (cubit) => cubit.startLocationTracking(),
      expect: () => const [
        HomeState(isLoading: true),
        HomeState(currentAddress: 'Tuburan, Pagadian'),
      ],
      verify: (_) {
        verify(() => currentLocationRepo.watchCurrentLocation()).called(1);
        verify(() => currentLocationRepo.getCurrentLocation()).called(1);
      },
    );

    test(
      'ignores an in-flight GPS fix after location access is lost',
      () async {
        final locationCompleter = Completer<Either<Failure, CurrentLocation>>();
        when(
          () => currentLocationRepo.watchCurrentLocation(),
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => currentLocationRepo.getCurrentLocation(),
        ).thenAnswer((_) => locationCompleter.future);

        final cubit = _makeCubit(repo, currentLocationRepo)
          ..updateAddress('SM City Pagadian');
        final start = cubit.startLocationTracking();
        await Future<void>.delayed(Duration.zero);

        await cubit.stopLocationTracking(clearAddress: true);
        locationCompleter.complete(
          const Right(
            CurrentLocation(latitude: 7.828282, longitude: 123.434343),
          ),
        );
        await start;

        expect(cubit.state.currentAddress, isEmpty);
        verifyNever(
          () => repo.loadHomeData(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        );
        await cubit.close();
      },
    );

    test('coalesces GPS updates behind one in-flight home request', () async {
      final locationStream =
          StreamController<Either<Failure, CurrentLocation>>();
      final firstRequest = Completer<Either<Failure, HomeData>>();
      final secondRequestStarted = Completer<void>();
      final requestedLatitudes = <double>[];
      var requestCount = 0;

      when(
        () => currentLocationRepo.watchCurrentLocation(),
      ).thenAnswer((_) => locationStream.stream);
      when(
        () => currentLocationRepo.getCurrentLocation(),
      ).thenAnswer((_) async => const Left(CurrentLocationFailure()));
      when(
        () => repo.loadHomeData(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer((invocation) {
        requestCount++;
        requestedLatitudes.add(invocation.namedArguments[#lat]! as double);
        if (requestCount == 1) return firstRequest.future;
        if (!secondRequestStarted.isCompleted) {
          secondRequestStarted.complete();
        }
        return Future.value(
          Right(
            HomeData(
              currentAddress: 'Latest pickup',
              recentLocations: const [],
            ),
          ),
        );
      });

      final cubit = _makeCubit(repo, currentLocationRepo);
      await cubit.startLocationTracking();

      locationStream.add(
        const Right(CurrentLocation(latitude: 7.8000, longitude: 123.4000)),
      );
      await Future<void>.delayed(Duration.zero);
      locationStream.add(
        const Right(CurrentLocation(latitude: 7.8100, longitude: 123.4100)),
      );
      locationStream.add(
        const Right(CurrentLocation(latitude: 7.8200, longitude: 123.4200)),
      );
      await Future<void>.delayed(Duration.zero);

      firstRequest.complete(
        Right(
          HomeData(currentAddress: 'First pickup', recentLocations: const []),
        ),
      );
      await secondRequestStarted.future.timeout(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);

      expect(requestedLatitudes, [7.8000, 7.8200]);
      expect(cubit.state.currentAddress, 'Latest pickup');

      await locationStream.close();
      await cubit.close();
    });
  });
}
