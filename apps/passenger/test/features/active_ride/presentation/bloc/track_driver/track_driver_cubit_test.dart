import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';

class MockTrackRepo extends Mock implements TrackRepository {}

class MockSecureSessionService extends Mock implements PassengerSessionStore {}

TrackDriverCubit _makeCubit(
  TrackRepository repo,
  PassengerSessionStore session,
) => TrackDriverCubit(
  repository: repo,
  sessionService: session,
  lifecycleCoordinator: AppLifecycleCoordinator(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTrackRepo repo;
  late MockSecureSessionService session;

  setUp(() {
    repo = MockTrackRepo();
    session = MockSecureSessionService();
    registerFallbackValue(RideStatus.unknown);
    when(() => session.saveActiveRideId(any())).thenAnswer((_) async {});
    when(() => session.readActiveRideId()).thenAnswer((_) async => null);
    when(() => session.clearSession()).thenAnswer((_) async {});
  });

  group('TrackDriverCubit — initial state', () {
    test('starts with TrackDriverInitial', () async {
      final cubit = _makeCubit(repo, session);
      expect(cubit.state, isA<TrackDriverInitial>());
      await cubit.close();
    });
  });

  group('TrackDriverCubit — cancelTrip()', () {
    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits TrackDriverCanceled when no active ride is stored',
      build: () => _makeCubit(repo, session),
      act: (cubit) => cubit.cancelTrip(),
      expect: () => [isA<TrackDriverCanceled>()],
    );

    blocTest<TrackDriverCubit, TrackDriverState>(
      'cancels active ride via repo when a stored rideId exists',
      build: () {
        when(() => session.readActiveRideId())
            .thenAnswer((_) async => 'ride-42');
        when(
          () => repo.cancelRide(
            rideId: any(named: 'rideId'),
            reason: any(named: 'reason'),
            details: any(named: 'details'),
          ),
        )
            .thenAnswer((_) async => const Ok(null));
        return _makeCubit(repo, session);
      },
      act: (cubit) => cubit.cancelTrip(),
      expect: () => [isA<TrackDriverCanceled>()],
      verify: (_) {
        verify(
          () => repo.cancelRide(
            rideId: 'ride-42',
            reason: 'passenger_changed_mind',
            details: '',
          ),
        ).called(1);
      },
    );

    test(
      'keeps the current ride state when cancellation is rejected',
      () async {
        when(() => session.readActiveRideId())
            .thenAnswer((_) async => 'ride-42');
        when(
          () => repo.cancelRide(
            rideId: any(named: 'rideId'),
            reason: any(named: 'reason'),
            details: any(named: 'details'),
          ),
        ).thenAnswer((_) async => const Err(NetworkFailure('cancel rejected')));
        final cubit = _makeCubit(repo, session);

        expect(await cubit.cancelTripRequest(), isFalse);
        expect(cubit.state, isA<TrackDriverInitial>());
        verify(
          () => repo.cancelRide(
            rideId: 'ride-42',
            reason: 'passenger_changed_mind',
            details: '',
          ),
        ).called(1);
        await cubit.close();
      },
    );
  });

  group('TrackDriverCubit — startTracking()', () {
    test(
      'reuses the active synchronization path for a realtime resync',
      () async {
        when(
          () => repo.getRoutePolyline(
            startLat: any(named: 'startLat'),
            startLng: any(named: 'startLng'),
            endLat: any(named: 'endLat'),
            endLng: any(named: 'endLng'),
          ),
        ).thenAnswer((_) async => null);
        when(() => repo.getRideStatusUpdate('ride-1')).thenAnswer(
          (_) async => const Ok(
            RideUpdate(
              status: RideStatus.accepted,
              driverId: 'drv-1',
              driverName: 'Driver',
              vehiclePlate: 'ABC-123',
              vehicleType: 'Sedan',
            ),
          ),
        );
        when(() => repo.fetchDriverLocation('ride-1'))
            .thenAnswer((_) async => const Ok((7.828, 123.434)));
        when(() => session.readActiveRideId())
            .thenAnswer((_) async => 'ride-1');
        final cubit = _makeCubit(repo, session);

        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
          rideId: 'ride-1',
          driverId: 'drv-1',
          driverName: 'Driver',
          vehiclePlate: 'ABC-123',
          vehicleType: 'Sedan',
        );
        await cubit.resyncActiveTrip();

        verify(() => repo.getRideStatusUpdate('ride-1')).called(2);
        await cubit.close();
      },
    );

    test('ignores a stale synchronization after a newer trip starts', () async {
      final firstStatusStarted = Completer<void>();
      final releaseFirstStatus = Completer<Result<RideUpdate, Failure>>();
      var sessionReads = 0;
      when(() => session.readActiveRideId()).thenAnswer((_) async {
        sessionReads++;
        return sessionReads == 1 ? 'ride-1' : 'ride-2';
      });
      when(() => repo.getRideStatusUpdate(any()))
          .thenAnswer((invocation) async {
            final rideId = invocation.positionalArguments.first as String;
            if (rideId == 'ride-1') {
              firstStatusStarted.complete();
              return releaseFirstStatus.future;
            }
            return const Ok(
              RideUpdate(
                status: RideStatus.accepted,
                driverId: 'driver-2',
                driverName: 'Driver 2',
                vehiclePlate: 'XYZ-2024',
                vehicleType: 'Sedan',
              ),
            );
          });
      when(() => repo.fetchDriverLocation(any())).thenAnswer((
        invocation,
      ) async {
        final rideId = invocation.positionalArguments.first as String;
        return rideId == 'ride-1' ? const Ok((1.0, 1.0)) : const Ok((2.0, 2.0));
      });
      when(
        () => repo.getRoutePolyline(
          startLat: any(named: 'startLat'),
          startLng: any(named: 'startLng'),
          endLat: any(named: 'endLat'),
          endLng: any(named: 'endLng'),
        ),
      ).thenAnswer((_) async => null);

      final cubit = _makeCubit(repo, session);
      final states = <TrackDriverState>[];
      final subscription = cubit.stream.listen(states.add);
      final firstStart = cubit.startTracking(
        startLat: 1,
        startLng: 1,
        endLat: 1.1,
        endLng: 1.1,
        rideId: 'ride-1',
        driverId: 'driver-1',
        driverName: 'Driver 1',
        vehiclePlate: 'ABC-1000',
        vehicleType: 'Sedan',
      );
      await firstStatusStarted.future;

      await cubit.startTracking(
        startLat: 2,
        startLng: 2,
        endLat: 2.1,
        endLng: 2.1,
        rideId: 'ride-2',
        driverId: 'driver-2',
        driverName: 'Driver 2',
        vehiclePlate: 'XYZ-2024',
        vehicleType: 'Sedan',
      );
      releaseFirstStatus.complete(
        const Ok(
          RideUpdate(
            status: RideStatus.accepted,
            driverId: 'driver-1',
            driverName: 'Driver 1',
            vehiclePlate: 'ABC-1000',
            vehicleType: 'Sedan',
          ),
        ),
      );
      await firstStart;

      final progressStates = states.whereType<TrackDriverInProgress>().toList();
      expect(progressStates, hasLength(1));
      expect(progressStates.single.driverLat, 2.0);
      expect(progressStates.single.driverLng, 2.0);

      await subscription.cancel();
      await cubit.close();
    });

    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits TrackDriverInProgress when repo returns route polyline',
      build: () {
        when(
          () => repo.getRoutePolyline(
            startLat: any(named: 'startLat'),
            startLng: any(named: 'startLng'),
            endLat: any(named: 'endLat'),
            endLng: any(named: 'endLng'),
          ),
        ).thenAnswer(
          (_) async => [
            [123.434, 7.828],
            [123.435, 7.829],
            [123.436, 7.830],
          ],
        );
        when(() => repo.getRideStatusUpdate(any())).thenAnswer(
          (_) async => const Ok(
            RideUpdate(
              status: RideStatus.accepted,
              driverId: 'drv-1',
              driverName: 'Driver',
              vehiclePlate: 'ABC-123',
              vehicleType: 'Sedan',
            ),
          ),
        );
        when(() => repo.fetchDriverLocation('ride-1'))
            .thenAnswer((_) async => const Ok((7.828, 123.434)));
        when(() => session.readActiveRideId())
            .thenAnswer((_) async => 'ride-1');
        return _makeCubit(repo, session);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
          rideId: 'ride-1',
          driverId: 'drv-1',
          driverName: 'Driver',
          vehiclePlate: 'ABC-123',
          vehicleType: 'Sedan',
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [isA<TrackDriverInProgress>()],
      skip: 0,
    );

    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits TrackDriverInProgress with the server location when route is unavailable',
      build: () {
        when(
          () => repo.getRoutePolyline(
            startLat: any(named: 'startLat'),
            startLng: any(named: 'startLng'),
            endLat: any(named: 'endLat'),
            endLng: any(named: 'endLng'),
          ),
        ).thenAnswer((_) async => null);
        when(() => repo.getRideStatusUpdate(any())).thenAnswer(
          (_) async => const Ok(
            RideUpdate(
              status: RideStatus.accepted,
              driverId: 'drv-1',
              driverName: 'driverName',
              vehiclePlate: 'ABC-123',
              vehicleType: 'Sedan',
            ),
          ),
        );
        when(() => repo.fetchDriverLocation('ride-1'))
            .thenAnswer((_) async => const Ok((7.828, 123.434)));
        when(() => session.readActiveRideId())
            .thenAnswer((_) async => 'ride-1');
        return _makeCubit(repo, session);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
          rideId: 'ride-1',
          driverId: 'drv-1',
          driverName: 'driverName',
          vehiclePlate: 'ABC-123',
          vehicleType: 'Sedan',
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [isA<TrackDriverInProgress>()],
      skip: 0,
    );

    blocTest<TrackDriverCubit, TrackDriverState>(
      'keeps an arrived status when driver location is temporarily unavailable',
      build: () {
        when(() => repo.getRideStatusUpdate(any())).thenAnswer(
          (_) async => const Ok(
            RideUpdate(
              status: RideStatus.arrived,
              driverId: 'drv-1',
              driverName: 'Driver',
              vehiclePlate: 'ABC-123',
              vehicleType: 'Sedan',
            ),
          ),
        );
        when(() => repo.fetchDriverLocation('ride-1'))
            .thenAnswer((_) async => const Err(NetworkFailure('offline')));
        when(() => session.readActiveRideId())
            .thenAnswer((_) async => 'ride-1');
        return _makeCubit(repo, session);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
          rideId: 'ride-1',
          driverId: 'drv-1',
          driverName: 'Driver',
          vehiclePlate: 'ABC-123',
          vehicleType: 'Sedan',
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [
        isA<TrackDriverInProgress>()
            .having((state) => state.status, 'status', RideStatus.arrived)
            .having((state) => state.driverLat, 'driverLat', 7.828)
            .having((state) => state.driverLng, 'driverLng', 123.434),
      ],
    );

    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits TrackDriverCompleted when server reports RideStatus.completed',
      build: () {
        when(
          () => repo.getRoutePolyline(
            startLat: any(named: 'startLat'),
            startLng: any(named: 'startLng'),
            endLat: any(named: 'endLat'),
            endLng: any(named: 'endLng'),
          ),
        ).thenAnswer((_) async => []);
        when(() => session.readActiveRideId())
            .thenAnswer((_) async => 'ride-1');
        when(() => repo.getRideStatusUpdate('ride-1')).thenAnswer(
          (_) async => const Ok(
            RideUpdate(
              status: RideStatus.completed,
              driverId: 'drv-1',
              driverName: 'Ali',
              vehiclePlate: 'ABC-123',
              vehicleType: 'Sedan',
            ),
          ),
        );
        return _makeCubit(repo, session);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          driverId: 'drv-1',
          driverName: 'Driver',
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
          rideId: 'ride-1',
          vehiclePlate: 'ABC-123',
          vehicleType: 'Sedan',
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [isA<TrackDriverCompleted>()],
      skip: 0,
    );
  });
}
