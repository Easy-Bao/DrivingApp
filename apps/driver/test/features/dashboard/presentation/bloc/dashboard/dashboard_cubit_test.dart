import 'package:bloc_test/bloc_test.dart';
import 'package:foundation/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dashboard_stats.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dispatch_snapshot.dart';
import 'package:driver/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';

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
        when(() => repo.getDashboardStats())
            .thenAnswer((_) async => const Left(ServerFailure('network')));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadStats(),
      expect: () => [
        const DashboardState(isLoadingStats: true),
        const DashboardState(
          isLoadingStats: false,
          statsErrorMessage: 'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'coalesces concurrent statistics loads',
      build: () {
        when(() => repo.getDashboardStats()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const Right(
            DriverDashboardStats(earnings: 12.50, completedTrips: 1),
          );
        });
        return _makeCubit(repo);
      },
      act: (cubit) async {
        await Future.wait([cubit.loadStats(), cubit.loadStats()]);
      },
      expect: () => [
        const DashboardState(isLoadingStats: true),
        const DashboardState(
          isLoadingStats: false,
          earnings: 12.50,
          completedTrips: 1,
        ),
      ],
      verify: (_) {
        verify(() => repo.getDashboardStats()).called(1);
      },
    );
  });

  group('DashboardCubit — initialize()', () {
    test(
      'restores the persisted online choice before loading statistics',
      () async {
        when(() => repo.getPersistedOnlineStatus())
            .thenAnswer((_) async => const Right(true));
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

    test('coalesces concurrent initialization requests', () async {
      when(() => repo.getPersistedOnlineStatus()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Right(false);
      });
      when(() => repo.getDashboardStats()).thenAnswer(
        (_) async =>
            const Right(DriverDashboardStats(earnings: 0, completedTrips: 0)),
      );

      final cubit = _makeCubit(repo);
      await Future.wait([cubit.initialize(), cubit.initialize()]);

      verify(() => repo.getPersistedOnlineStatus()).called(1);
      verify(() => repo.getDashboardStats()).called(1);
      await cubit.close();
    });
  });

  group('DashboardCubit — dispatch feed', () {
    test('resync bypasses the silent polling cooldown', () async {
      var requestCount = 0;
      when(() => repo.getDispatchSnapshot(includeOffers: true))
          .thenAnswer((_) async {
            requestCount++;
            if (requestCount == 1) {
              return const Left(NetworkFailure('service unavailable'));
            }
            return const Right(
              DriverDispatchSnapshot(
                activeTrips: [
                  {'id': 'trip-1', 'status': 'in_transit'},
                ],
                rideOffers: [],
              ),
            );
          });
      final cubit = DashboardCubit(
        repository: repo,
        now: () => DateTime.utc(2026, 8, 28, 8),
      );

      expect(await cubit.loadDispatchSnapshot(silent: true), isFalse);
      await cubit.resyncActiveTrip();

      expect(cubit.state.activeTrips.single['id'], 'trip-1');
      verify(() => repo.getDispatchSnapshot(includeOffers: true)).called(2);
      await cubit.close();
    });

    test(
      'cools down silent polling after the service becomes unreachable',
      () async {
        var now = DateTime.utc(2026, 8, 28, 8);
        when(() => repo.getDispatchSnapshot(includeOffers: true)).thenAnswer(
          (_) async => const Left(NetworkFailure('service unavailable')),
        );
        final cubit = DashboardCubit(repository: repo, now: () => now);

        expect(await cubit.loadDispatchSnapshot(silent: true), isFalse);
        expect(await cubit.loadDispatchSnapshot(silent: true), isFalse);
        verify(() => repo.getDispatchSnapshot(includeOffers: true)).called(1);

        now = now.add(const Duration(seconds: 16));
        expect(await cubit.loadDispatchSnapshot(silent: true), isFalse);
        verify(() => repo.getDispatchSnapshot(includeOffers: true)).called(1);
        await cubit.close();
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'loads and sorts active trips while keeping offers in cubit state',
      build: () {
        when(() => repo.getDispatchSnapshot(includeOffers: true)).thenAnswer(
          (_) async => const Right(
            DriverDispatchSnapshot(
              activeTrips: [
                {
                  'id': 'accepted-trip',
                  'status': 'accepted',
                  'created_at': '2026-08-26T10:00:00Z',
                },
                {
                  'id': 'transit-trip',
                  'status': 'in_transit',
                  'created_at': '2026-08-26T11:00:00Z',
                },
              ],
              rideOffers: [
                {'id': 'offer-1', 'expires_at': '2099-01-01T00:00:00Z'},
              ],
            ),
          ),
        );
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadDispatchSnapshot(),
      expect: () => [
        const DashboardState(isLoadingDispatch: true),
        const DashboardState(
          activeTrips: [
            {
              'id': 'transit-trip',
              'status': 'in_transit',
              'created_at': '2026-08-26T11:00:00Z',
            },
            {
              'id': 'accepted-trip',
              'status': 'accepted',
              'created_at': '2026-08-26T10:00:00Z',
            },
          ],
          activeBids: [
            {'id': 'offer-1', 'expires_at': '2099-01-01T00:00:00Z'},
          ],
        ),
      ],
    );

    test('merges realtime trips without mutating existing state', () async {
      when(() => repo.getDispatchSnapshot(includeOffers: true)).thenAnswer(
        (_) async => const Right(
          DriverDispatchSnapshot(
            activeTrips: [
              {'id': 'trip-1', 'status': 'accepted'},
            ],
            rideOffers: [],
          ),
        ),
      );
      final cubit = _makeCubit(repo);
      await cubit.loadDispatchSnapshot();
      final initialTrips = cubit.state.activeTrips;

      cubit.mergeActiveTrip(const {'id': 'trip-1', 'status': 'in_transit'});

      expect(initialTrips.single['status'], 'accepted');
      expect(cubit.state.activeTrips.single['status'], 'in_transit');
      expect(() => cubit.state.activeTrips.add({}), throwsUnsupportedError);
      await cubit.close();
    });
  });

  group('DashboardCubit — toggleOnline()', () {
    const lat = 7.828282;
    const lng = 123.434343;

    blocTest<DashboardCubit, DashboardState>(
      'going online emits the confirmed online state',
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
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [const DashboardState(isOnline: true)],
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
      seed: () => const DashboardState(isOnline: true),
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [const DashboardState(isOnline: false)],
    );

    blocTest<DashboardCubit, DashboardState>(
      'honors the switch value instead of inferring it from stale state',
      build: () {
        when(() => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng))
            .thenAnswer((_) async => const Right(null));
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
        when(() => repo.updateOnlineStatus(isOnline: true, lat: lat, lng: lng))
            .thenAnswer(
              (_) async => const Left(NetworkFailure('location unavailable')),
            );
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(isOnline: true),
        const DashboardState(
          errorMessage: 'You are currently offline. Please check your Wi-Fi or mobile data.',
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'rolls back an optimistic offline transition when the server rejects it',
      build: () {
        when(() => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng))
            .thenAnswer(
              (_) async => const Left(NetworkFailure('offline update failed')),
            );
        return _makeCubit(repo);
      },
      seed: () => const DashboardState(isOnline: true),
      act: (cubit) =>
          cubit.toggleOnline(requestedOnline: false, lat: lat, lng: lng),
      expect: () => [
        const DashboardState(isOnline: false),
        const DashboardState(
          isOnline: true,
          errorMessage: 'You are currently offline. Please check your Wi-Fi or mobile data.',
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'forces the driver offline when location access is lost',
      build: () {
        when(() => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng))
            .thenAnswer((_) async => const Right(null));
        return _makeCubit(repo);
      },
      seed: () => const DashboardState(isOnline: true),
      act: (cubit) => cubit.forceOffline(lat: lat, lng: lng),
      expect: () => [const DashboardState(isOnline: false)],
    );

    blocTest<DashboardCubit, DashboardState>(
      'failed presence refresh preserves the driver online preference',
      build: () {
        when(() => repo.updateOnlineStatus(isOnline: true, lat: lat, lng: lng))
            .thenAnswer(
              (_) async => const Left(NetworkFailure('presence unavailable')),
            );
        return _makeCubit(repo);
      },
      seed: () => const DashboardState(isOnline: true),
      act: (cubit) => cubit.refreshOnlinePresence(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(
          isOnline: true,
          errorMessage: 'You are currently offline. Please check your Wi-Fi or mobile data.',
        ),
      ],
    );

    test(
      'forceOffline reconciles the server even from local offline state',
      () async {
        when(() => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng))
            .thenAnswer((_) async => const Right(null));
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
