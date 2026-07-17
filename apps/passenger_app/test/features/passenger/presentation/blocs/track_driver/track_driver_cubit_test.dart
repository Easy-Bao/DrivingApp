import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_state.dart';
import 'package:session_service/session_service.dart';

class MockTrackRepo extends Mock implements TrackRepository {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

TrackDriverCubit _makeCubit(
  TrackRepository repo,
  SecureSessionService session,
) => TrackDriverCubit(repository: repo, sessionService: session);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTrackRepo repo;
  late MockSecureSessionService session;

  setUp(() {
    repo = MockTrackRepo();
    session = MockSecureSessionService();
    registerFallbackValue(RideStatus.unknown);
    // Default stubs for session calls made in startTracking and cancelTrip.
    when(() => session.writeActiveRideId(any())).thenAnswer((_) async {});
    when(() => session.readActiveRideId()).thenAnswer((_) async => null);
    when(() => session.deleteActiveRideId()).thenAnswer((_) async {});
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
        verify(() => session.deleteActiveRideId()).called(1);
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
        when(
          () => repo.getRideStatusUpdate(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('error')));
        return _makeCubit(repo, session);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
          rideId: 'ride-1',
          driverName: 'Driver',
          vehiclePlate: 'ABC-123',
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [isA<TrackDriverInProgress>()],
      skip: 0,
    );

    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits TrackDriverInProgress using linear interpolation when polyline is null',
      build: () {
        when(
          () => repo.getRoutePolyline(
            startLat: any(named: 'startLat'),
            startLng: any(named: 'startLng'),
            endLat: any(named: 'endLat'),
            endLng: any(named: 'endLng'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => repo.getRideStatusUpdate(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('error')));
        return _makeCubit(repo, session);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
          rideId: 'ride-1',
          driverName: 'driverName',
          vehiclePlate: 'ABC-123',
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [isA<TrackDriverInProgress>()],
      skip: 0,
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
          driverName: 'Driver',
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
          rideId: 'ride-1',
          vehiclePlate: 'ABC-123',
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [isA<TrackDriverCompleted>()],
      skip: 0,
    );
  });
}
