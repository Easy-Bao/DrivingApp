import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:foundation/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
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
    test('ignores a statistics result after the cubit closes', () async {
      final statsStarted = Completer<void>();
      final releaseStats = Completer<Result<DriverDashboardStats, Failure>>();
      when(() => repo.getDashboardStats()).thenAnswer((_) {
        statsStarted.complete();
        return releaseStats.future;
      });

      final cubit = _makeCubit(repo);
      final states = <DashboardState>[];
      final subscription = cubit.stream.listen(states.add);
      final pendingLoad = cubit.loadStats();
      await statsStarted.future;

      await cubit.close();
      releaseStats.complete(
        const Ok(DriverDashboardStats(earnings: 42, completedTrips: 2)),
      );
      await pendingLoad;

      expect(states, [const DashboardState(isLoadingStats: true)]);
      await subscription.cancel();
    });

    blocTest<DashboardCubit, DashboardState>(
      'emits [loading=true, loaded with values] on success',
      build: () {
        when(
          () => repo.updateOnlineStatus(
            isOnline: any(named: 'isOnline'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Ok(null));
        when(() => repo.getDashboardStats()).thenAnswer(
          (_) async => const Ok(
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
          hasLoadedStats: true,
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
        ).thenAnswer((_) async => const Ok(null));
        when(() => repo.getDashboardStats())
            .thenAnswer((_) async => const Err(ServerFailure('network')));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.loadStats(),
      expect: () => [
        const DashboardState(isLoadingStats: true),
        const DashboardState(
          isLoadingStats: false,
          statsErrorMessage: 'Something went wrong. Try again.',
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'keeps loaded statistics when a refresh fails',
      build: () {
        var requestCount = 0;
        when(() => repo.getDashboardStats()).thenAnswer((_) async {
          requestCount++;
          if (requestCount == 1) {
            return const Ok(
              DriverDashboardStats(earnings: 385.50, completedTrips: 7),
            );
          }
          return const Err(ServerFailure('network'));
        });
        return _makeCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadStats();
        await cubit.loadStats();
      },
      expect: () => [
        const DashboardState(isLoadingStats: true),
        const DashboardState(
          isLoadingStats: false,
          hasLoadedStats: true,
          earnings: 385.50,
          completedTrips: 7,
        ),
        const DashboardState(
          isLoadingStats: true,
          hasLoadedStats: true,
          earnings: 385.50,
          completedTrips: 7,
        ),
        const DashboardState(
          isLoadingStats: false,
          hasLoadedStats: true,
          earnings: 385.50,
          completedTrips: 7,
          statsErrorMessage: 'Something went wrong. Try again.',
        ),
      ],
      verify: (_) {
        verify(() => repo.getDashboardStats()).called(2);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'coalesces concurrent statistics loads',
      build: () {
        when(() => repo.getDashboardStats()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const Ok(
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
          hasLoadedStats: true,
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
            .thenAnswer((_) async => const Ok(true));
        when(() => repo.getDashboardStats()).thenAnswer(
          (_) async =>
              const Ok(DriverDashboardStats(earnings: 0, completedTrips: 0)),
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
        return const Ok(false);
      });
      when(() => repo.getDashboardStats()).thenAnswer(
        (_) async =>
            const Ok(DriverDashboardStats(earnings: 0, completedTrips: 0)),
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
              return const Err(NetworkFailure('service unavailable'));
            }
            return const Ok(
              DriverDispatchSnapshot(
                activeRide: RideSnapshot(
                  id: 'trip-1',
                  status: 'in_transit',
                  pickupName: 'Pickup',
                  dropoffName: 'Dropoff',
                ),
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

      expect(cubit.state.activeRide?.id, 'trip-1');
      verify(() => repo.getDispatchSnapshot(includeOffers: true)).called(2);
      await cubit.close();
    });

    test(
      'cools down silent polling after the service becomes unreachable',
      () async {
        var now = DateTime.utc(2026, 8, 28, 8);
        when(() => repo.getDispatchSnapshot(includeOffers: true)).thenAnswer(
          (_) async => const Err(NetworkFailure('service unavailable')),
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
      'keeps one active ride and clears offers returned with that ride',
      build: () {
        when(() => repo.getDispatchSnapshot(includeOffers: true)).thenAnswer(
          (_) async => const Ok(
            DriverDispatchSnapshot(
              activeRide: RideSnapshot(
                id: 'transit-trip',
                status: 'in_transit',
                pickupName: 'Pickup',
                dropoffName: 'Dropoff',
              ),
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
          activeRide: RideSnapshot(
            id: 'transit-trip',
            status: 'in_transit',
            pickupName: 'Pickup',
            dropoffName: 'Dropoff',
          ),
        ),
      ],
    );

    test(
      'realtime active ride clears offers and replaces the current ride',
      () async {
        when(() => repo.getDispatchSnapshot(includeOffers: true)).thenAnswer(
          (_) async => const Ok(
            DriverDispatchSnapshot(
              rideOffers: [
                {'id': 'offer-1', 'expires_at': '2099-01-01T00:00:00Z'},
              ],
            ),
          ),
        );
        final cubit = _makeCubit(repo);
        await cubit.loadDispatchSnapshot();

        cubit.mergeActiveRide(
          const RideSnapshot(
            id: 'trip-1',
            status: 'accepted',
            pickupName: 'Pickup',
            dropoffName: 'Dropoff',
          ),
        );
        cubit.mergeActiveRide(
          const RideSnapshot(
            id: 'trip-2',
            status: 'arrived',
            pickupName: 'Pickup 2',
            dropoffName: 'Dropoff 2',
          ),
        );

        expect(cubit.state.activeRide?.id, 'trip-2');
        expect(cubit.state.activeBids, isEmpty);
        await cubit.close();
      },
    );

    test(
      'does not fetch incoming offers while an active ride exists',
      () async {
        when(() => repo.getDispatchSnapshot(includeOffers: false)).thenAnswer(
          (_) async => const Ok(
            DriverDispatchSnapshot(
              activeRide: RideSnapshot(
                id: 'trip-1',
                status: 'in_transit',
                pickupName: 'Pickup',
                dropoffName: 'Dropoff',
              ),
              rideOffers: [
                {'id': 'offer-1', 'expires_at': '2099-01-01T00:00:00Z'},
              ],
            ),
          ),
        );
        final cubit = _makeCubit(repo);
        cubit.mergeActiveRide(
          const RideSnapshot(
            id: 'trip-1',
            status: 'accepted',
            pickupName: 'Pickup',
            dropoffName: 'Dropoff',
          ),
        );

        await cubit.loadDispatchSnapshot();

        verify(() => repo.getDispatchSnapshot(includeOffers: false)).called(1);
        verifyNever(() => repo.getDispatchSnapshot(includeOffers: true));
        expect(cubit.state.activeBids, isEmpty);
        await cubit.close();
      },
    );

    test('ignores a stale snapshot after a realtime ride is matched', () async {
      final response = Completer<Result<DriverDispatchSnapshot, Failure>>();
      when(() => repo.getDispatchSnapshot(includeOffers: true))
          .thenAnswer((_) => response.future);
      final cubit = _makeCubit(repo);
      final pendingSnapshot = cubit.loadDispatchSnapshot();

      const matchedRide = RideSnapshot(
        id: 'matched-trip',
        status: 'accepted',
        pickupName: 'Pickup',
        dropoffName: 'Dropoff',
      );
      cubit.mergeActiveRide(matchedRide);
      response.complete(
        const Ok(
          DriverDispatchSnapshot(
            rideOffers: [
              {'id': 'stale-offer'},
            ],
          ),
        ),
      );
      await pendingSnapshot;

      expect(cubit.state.activeRide, matchedRide);
      expect(cubit.state.activeBids, isEmpty);
      await cubit.close();
    });

    test(
      'does not restore a ride removed while a snapshot is pending',
      () async {
        final response = Completer<Result<DriverDispatchSnapshot, Failure>>();
        when(() => repo.getDispatchSnapshot(includeOffers: false))
            .thenAnswer((_) => response.future);
        final cubit = _makeCubit(repo);
        const activeRide = RideSnapshot(
          id: 'finished-trip',
          status: 'in_transit',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        );
        cubit.mergeActiveRide(activeRide);
        final pendingSnapshot = cubit.loadDispatchSnapshot();

        cubit.removeActiveRide(activeRide.id);
        response.complete(
          const Ok(
            DriverDispatchSnapshot(activeRide: activeRide, rideOffers: []),
          ),
        );
        await pendingSnapshot;

        expect(cubit.state.activeRide, isNull);
        expect(cubit.state.activeBids, isEmpty);
        await cubit.close();
      },
    );

    test(
      'ignores a terminal ride in later realtime and snapshot updates',
      () async {
        const finishedRide = RideSnapshot(
          id: 'finished-trip',
          status: 'in_transit',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        );
        when(() => repo.getDispatchSnapshot(includeOffers: true)).thenAnswer(
          (_) async => const Ok(
            DriverDispatchSnapshot(activeRide: finishedRide, rideOffers: []),
          ),
        );
        final cubit = _makeCubit(repo);
        cubit.mergeActiveRide(finishedRide);

        cubit.removeActiveRide(finishedRide.id);
        cubit.mergeActiveRide(finishedRide);
        await cubit.loadDispatchSnapshot();

        expect(cubit.state.activeRide, isNull);
        await cubit.close();
      },
    );

    test('removes only the matching active ride', () async {
      final cubit = _makeCubit(repo);
      cubit.mergeActiveRide(
        const RideSnapshot(
          id: 'trip-1',
          status: 'accepted',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        ),
      );

      cubit.removeActiveRide('stale-trip');
      expect(cubit.state.activeRide?.id, 'trip-1');

      cubit.removeActiveRide('trip-1');

      expect(cubit.state.activeRide, isNull);
      expect(cubit.state.activeBids, isEmpty);
      await cubit.close();
    });

    test(
      'keeps submitted offers pending and ignores stale snapshots',
      () async {
        final now = DateTime.utc(2026, 10, 12, 10);
        final expiresAt = now
            .add(const Duration(seconds: 90))
            .toIso8601String();
        var snapshot = DriverDispatchSnapshot(
          rideOffers: [
            {'id': 'session-1', 'offered_fare': 25000, 'expires_at': expiresAt},
          ],
        );
        final staleResponse =
            Completer<Result<DriverDispatchSnapshot, Failure>>();
        final staleRequestStarted = Completer<void>();
        var snapshotRequestCount = 0;
        when(() => repo.getDispatchSnapshot(includeOffers: true))
            .thenAnswer((_) {
              snapshotRequestCount++;
              if (snapshotRequestCount == 2) {
                staleRequestStarted.complete();
                return staleResponse.future;
              }
              return Future.value(Ok(snapshot));
            });
        when(() => repo.submitRideOffer(sessionId: 'session-1', farePesos: 250))
            .thenAnswer((_) async => const Ok(null));
        final cubit = DashboardCubit(repository: repo, now: () => now);

        await cubit.loadDispatchSnapshot();
        expect(cubit.state.activeBids, hasLength(1));

        final staleLoad = cubit.loadDispatchSnapshot();
        await staleRequestStarted.future;
        expect(
          await cubit.submitRideOffer(sessionId: 'session-1', farePesos: 250),
          isTrue,
        );
        expect(cubit.state.activeBids, isEmpty);
        expect(
          cubit.state.submittedOffers.single['local_offer_submitted'],
          isTrue,
        );
        staleResponse.complete(
          Ok(
            DriverDispatchSnapshot(
              rideOffers: [
                {
                  'id': 'session-1',
                  'offered_fare': 25000,
                  'expires_at': expiresAt,
                },
              ],
            ),
          ),
        );
        await staleLoad;
        expect(cubit.state.submittedOffers, hasLength(1));
        expect(cubit.state.activeBids, isEmpty);

        snapshot = DriverDispatchSnapshot(
          rideOffers: [
            {
              'id': 'session-1',
              'offered_fare': 25000,
              'expires_at': expiresAt,
              'offers': [
                {'status': 'pending', 'proposed_fare': 25000},
              ],
            },
          ],
        );
        await cubit.loadDispatchSnapshot();
        expect(cubit.state.submittedOffers, hasLength(1));
        expect(cubit.state.activeBids, isEmpty);

        expect(cubit.resolveSubmittedOffer('session-1'), isTrue);
        expect(cubit.state.submittedOffers, isEmpty);

        await cubit.loadDispatchSnapshot();
        expect(cubit.state.submittedOffers, isEmpty);
        expect(cubit.state.activeBids, isEmpty);
        await cubit.close();
      },
    );

    test('reports when a submitted offer expires', () async {
      var now = DateTime.utc(2026, 10, 12, 10);
      final expiresAt = now.add(const Duration(seconds: 30));
      when(() => repo.getDispatchSnapshot(includeOffers: true)).thenAnswer(
        (_) async => Ok(
          DriverDispatchSnapshot(
            rideOffers: [
              {
                'id': 'session-2',
                'expires_at': expiresAt.toIso8601String(),
                'offers': [
                  {'status': 'pending', 'proposed_fare': 20000},
                ],
              },
            ],
          ),
        ),
      );
      final cubit = DashboardCubit(repository: repo, now: () => now);

      await cubit.loadDispatchSnapshot();
      expect(cubit.state.submittedOffers, hasLength(1));

      now = expiresAt.add(const Duration(seconds: 1));
      expect(cubit.removeExpiredRideOffers(), isTrue);
      expect(cubit.state.submittedOffers, isEmpty);
      expect(cubit.removeExpiredRideOffers(), isFalse);
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
        ).thenAnswer((_) async => const Ok(null));
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
        ).thenAnswer((_) async => const Ok(null));
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
            .thenAnswer((_) async => const Ok(null));
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
              (_) async => const Err(NetworkFailure('location unavailable')),
            );
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.toggleOnline(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(isOnline: true),
        const DashboardState(
          errorMessage:
              "Couldn't connect. Check your internet connection and try again.",
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'rolls back an optimistic offline transition when the server rejects it',
      build: () {
        when(() => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng))
            .thenAnswer(
              (_) async => const Err(NetworkFailure('offline update failed')),
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
          errorMessage:
              "Couldn't connect. Check your internet connection and try again.",
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'forces the driver offline when location access is lost',
      build: () {
        when(() => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng))
            .thenAnswer((_) async => const Ok(null));
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
              (_) async => const Err(NetworkFailure('presence unavailable')),
            );
        return _makeCubit(repo);
      },
      seed: () => const DashboardState(isOnline: true),
      act: (cubit) => cubit.refreshOnlinePresence(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(
          isOnline: true,
          errorMessage:
              "Couldn't connect. Check your internet connection and try again.",
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'reconciles a rejected online lease to offline',
      build: () {
        when(() => repo.updateOnlineStatus(isOnline: true, lat: lat, lng: lng))
            .thenAnswer(
              (_) async => const Err(
                ServerFailure.withStatusCode('availability restricted', 403),
              ),
            );
        when(() => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng))
            .thenAnswer((_) async => const Ok(null));
        return _makeCubit(repo);
      },
      seed: () => const DashboardState(isOnline: true),
      act: (cubit) => cubit.refreshOnlinePresence(lat: lat, lng: lng),
      expect: () => [
        const DashboardState(
          errorMessage: "You don't have permission to do that.",
        ),
      ],
      verify: (_) {
        verify(
          () => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng),
        ).called(1);
      },
    );

    test(
      'forceOffline reconciles the server even from local offline state',
      () async {
        when(() => repo.updateOnlineStatus(isOnline: false, lat: lat, lng: lng))
            .thenAnswer((_) async => const Ok(null));
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
