import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:shared_core/shared_core.dart';

class MockTrackRepo extends Mock implements ITrackRepository {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

TrackDriverCubit _makeCubit(
  ITrackRepository repo,
  SecureSessionService session,
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
        when(
          () => session.readActiveRideId(),
        ).thenAnswer((_) async => 'ride-42');
        when(
          () => repo.updateRideStatus(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        return _makeCubit(repo, session);
      },
      act: (cubit) => cubit.cancelTrip(),
      expect: () => [isA<TrackDriverCanceled>()],
      verify: (_) {
        verify(
          () => repo.updateRideStatus('ride-42', RideStatus.cancelled),
        ).called(1);
      },
    );
  });

  group('TrackDriverCubit — startTracking()', () {
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
          (_) async => const Right(
            RideUpdate(
              status: RideStatus.accepted,
              driverId: 'drv-1',
              driverName: 'Driver',
              vehiclePlate: 'ABC-123',
              vehicleType: 'Sedan',
            ),
          ),
        );
        when(
          () => repo.fetchDriverLocation('ride-1'),
        ).thenAnswer((_) async => const Right((7.828, 123.434)));
        when(
          () => session.readActiveRideId(),
        ).thenAnswer((_) async => 'ride-1');
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
          (_) async => const Right(
            RideUpdate(
              status: RideStatus.accepted,
              driverId: 'drv-1',
              driverName: 'driverName',
              vehiclePlate: 'ABC-123',
              vehicleType: 'Sedan',
            ),
          ),
        );
        when(
          () => repo.fetchDriverLocation('ride-1'),
        ).thenAnswer((_) async => const Right((7.828, 123.434)));
        when(
          () => session.readActiveRideId(),
        ).thenAnswer((_) async => 'ride-1');
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
          (_) async => const Right(
            RideUpdate(
              status: RideStatus.arrived,
              driverId: 'drv-1',
              driverName: 'Driver',
              vehiclePlate: 'ABC-123',
              vehicleType: 'Sedan',
            ),
          ),
        );
        when(
          () => repo.fetchDriverLocation('ride-1'),
        ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
        when(
          () => session.readActiveRideId(),
        ).thenAnswer((_) async => 'ride-1');
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
        when(
          () => session.readActiveRideId(),
        ).thenAnswer((_) async => 'ride-1');
        when(() => repo.getRideStatusUpdate('ride-1')).thenAnswer(
          (_) async => const Right(
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
