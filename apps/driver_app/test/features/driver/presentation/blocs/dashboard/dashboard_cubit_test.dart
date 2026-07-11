import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardRepo extends Mock implements DashboardRepository {}

DashboardCubit _makeCubit(DashboardRepository repo) =>
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
        when(() => repo.getTodayEarnings()).thenAnswer((_) async => 385.50);
        when(() => repo.getTodayTrips()).thenAnswer((_) async => 7);
        when(() => repo.getHoursOnline()).thenAnswer((_) async => 4.5);
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadStats(),
      expect: () => [
        const DashboardState(isLoadingStats: true),
        const DashboardState(
          isLoadingStats: false,
          todayEarnings: 385.50,
          todayTrips: 7,
          hoursOnline: 4.5,
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits [loading=true, loading=false] on repository error',
      build: () {
        when(() => repo.getTodayEarnings()).thenThrow(Exception('network'));
        when(() => repo.getTodayTrips()).thenThrow(Exception('network'));
        when(() => repo.getHoursOnline()).thenThrow(Exception('network'));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadStats(),
      expect: () => [
        const DashboardState(isLoadingStats: true),
        const DashboardState(isLoadingStats: false),
      ],
    );
  });

  group('DashboardCubit — toggleOnline()', () {
    const lat = 7.828282;
    const lng = 123.434343;
    final mockCells = const [
      HeatmapCell(lat: lat + 0.002, lng: lng - 0.002, intensity: 2.5),
    ];

    blocTest<DashboardCubit, DashboardState>(
      'going online fetches heatmap and emits [online+loading, online+cells]',
      build: () {
        when(
          () => repo.getSurgeHeatmap(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            gridSize: any(named: 'gridSize'),
            cellSize: any(named: 'cellSize'),
            requestLats: any(named: 'requestLats'),
            requestLngs: any(named: 'requestLngs'),
          ),
        ).thenAnswer((_) async => mockCells);
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
          () => repo.getSurgeHeatmap(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            gridSize: any(named: 'gridSize'),
            cellSize: any(named: 'cellSize'),
            requestLats: any(named: 'requestLats'),
            requestLngs: any(named: 'requestLngs'),
          ),
        ).thenThrow(Exception('map error'));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(isOnline: true, isLoadingHeatmap: true),
        const DashboardState(isOnline: true),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'going offline clears online flag and surge cells',
      build: () => _makeCubit(repo),
      seed: () => DashboardState(isOnline: true, surgeCells: mockCells),
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [const DashboardState(isOnline: false)],
    );
  });
}
