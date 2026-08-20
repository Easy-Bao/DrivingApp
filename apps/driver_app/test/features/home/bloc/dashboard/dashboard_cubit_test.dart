import 'package:bloc_test/bloc_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/features/home/data/models/heatmap_cell_model.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dashboard_stats.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_state.dart';

class MockDashboardRepo extends Mock implements IDashboardRepository {}

DashboardCubit _makeCubit(IDashboardRepository repo) =>
    DashboardCubit(repository: repo);

void main() {
  late MockDashboardRepo repo;

  setUp(() {
    repo = MockDashboardRepo();
  });

  group('DashboardCubit — initial state', () {
    test('starts with all defaults', () async {
      final cubit = _makeCubit(repo);
      expect(cubit.state, const DashboardState());
      await cubit.close();
    });
  });

  group('DashboardCubit — loadStats()', () {
    blocTest<DashboardCubit, DashboardState>(
      'emits [loading=true, loaded with values] on success',
      build: () {
        when(
          () => repo.updateOnlineStatus(
            isOnline: any(named: 'isOnline'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(() => repo.getDashboardStats()).thenAnswer(
          (_) async => const Right(
            DriverDashboardStats(earnings: 385.50, completedTrips: 7),
          ),
        );
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadStats(),
      expect: () => [
        const DashboardState(isLoadingStats: true),
        const DashboardState(
          isLoadingStats: false,
          earnings: 385.50,
          completedTrips: 7,
        ),
      ],
      verify: (_) {
        verify(() => repo.getDashboardStats()).called(1);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits [loading=true, loading=false] on repository error',
      build: () {
        when(
          () => repo.updateOnlineStatus(
            isOnline: any(named: 'isOnline'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => repo.getDashboardStats(),
        ).thenAnswer((_) async => const Left(ServerFailure('network')));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadStats(),
      expect: () => [
        const DashboardState(isLoadingStats: true),
        const DashboardState(
          isLoadingStats: false,
          errorMessage:
              'The service is temporarily unavailable. Please try again.',
        ),
      ],
    );
  });

  group('DashboardCubit — initialize()', () {
    test(
      'restores the persisted online choice before loading statistics',
      () async {
        when(
          () => repo.getPersistedOnlineStatus(),
        ).thenAnswer((_) async => const Right(true));
        when(() => repo.getDashboardStats()).thenAnswer(
          (_) async =>
              const Right(DriverDashboardStats(earnings: 0, completedTrips: 0)),
        );

        final cubit = _makeCubit(repo);
        await cubit.initialize();

        expect(cubit.state.isOnline, isTrue);
        verify(() => repo.getPersistedOnlineStatus()).called(1);
        await cubit.close();
      },
    );
  });

  group('DashboardCubit — toggleOnline()', () {
    const lat = 7.828282;
    const lng = 123.434343;
    final mockCells = <HeatmapCell>[
      HeatmapCell(lat: lat + 0.002, lng: lng - 0.002, intensity: 2.5),
    ];

    blocTest<DashboardCubit, DashboardState>(
      'going online fetches heatmap and emits [online+loading, online+cells]',
      build: () {
        when(
          () => repo.updateOnlineStatus(
            isOnline: any(named: 'isOnline'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => repo.getSurgeHeatmap(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            gridSize: any(named: 'gridSize'),
            cellSize: any(named: 'cellSize'),
            requestLats: any(named: 'requestLats'),
            requestLngs: any(named: 'requestLngs'),
          ),
        ).thenAnswer((_) async => Right(mockCells));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(isOnline: true, isLoadingHeatmap: true),
        DashboardState(isOnline: true, surgeCells: mockCells),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'going online with heatmap failure still stays online with empty cells',
      build: () {
        when(
          () => repo.updateOnlineStatus(
            isOnline: any(named: 'isOnline'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => repo.getSurgeHeatmap(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            gridSize: any(named: 'gridSize'),
            cellSize: any(named: 'cellSize'),
            requestLats: any(named: 'requestLats'),
            requestLngs: any(named: 'requestLngs'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('map error')));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(isOnline: true, isLoadingHeatmap: true),
        const DashboardState(
          isOnline: true,
          errorMessage:
              'The service is temporarily unavailable. Please try again.',
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'going offline clears online flag and surge cells',
      build: () {
        when(
          () => repo.updateOnlineStatus(
            isOnline: any(named: 'isOnline'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return _makeCubit(repo);
      },
      seed: () => DashboardState(isOnline: true, surgeCells: mockCells),
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [const DashboardState(isOnline: false)],
    );

    blocTest<DashboardCubit, DashboardState>(
      'honors the switch value instead of inferring it from stale state',
      build: () {
        when(
          () => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng),
        ).thenAnswer((_) async => const Right(null));
        return _makeCubit(repo);
      },
      act: (cubit) =>
          cubit.toggleOnline(requestedOnline: false, lat: lat, lng: lng),
      expect: () => [const DashboardState(isOnline: false)],
      verify: (_) {
        verify(
          () => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng),
        ).called(1);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'failed online transition keeps the rendered driver offline',
      build: () {
        when(
          () => repo.updateOnlineStatus(isOnline: true, lat: lat, lng: lng),
        ).thenAnswer(
          (_) async => const Left(NetworkFailure('location unavailable')),
        );
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(
          errorMessage: 'Check your connection and try again.',
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'forces the driver offline when location access is lost',
      build: () {
        when(
          () => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng),
        ).thenAnswer((_) async => const Right(null));
        return _makeCubit(repo);
      },
      seed: () => DashboardState(isOnline: true, surgeCells: mockCells),
      act: (cubit) => cubit.forceOffline(lat: lat, lng: lng),
      expect: () => [const DashboardState(isOnline: false)],
    );

    blocTest<DashboardCubit, DashboardState>(
      'failed presence refresh preserves the driver online preference',
      build: () {
        when(
          () => repo.updateOnlineStatus(isOnline: true, lat: lat, lng: lng),
        ).thenAnswer(
          (_) async => const Left(NetworkFailure('presence unavailable')),
        );
        return _makeCubit(repo);
      },
      seed: () => DashboardState(isOnline: true, surgeCells: mockCells),
      act: (cubit) => cubit.refreshOnlinePresence(lat: lat, lng: lng),
      expect: () => [
        DashboardState(
          isOnline: true,
          surgeCells: mockCells,
          errorMessage: 'Check your connection and try again.',
        ),
      ],
    );

    test(
      'forceOffline reconciles the server even from local offline state',
      () async {
        when(
          () => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng),
        ).thenAnswer((_) async => const Right(null));
        final cubit = _makeCubit(repo);

        await cubit.forceOffline(lat: lat, lng: lng);

        verify(
          () => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng),
        ).called(1);
        await cubit.close();
      },
    );
  });
}
