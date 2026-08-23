import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/datasources/ride_remote_data_source.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_state.dart';

class MockRideRemoteDataSource extends Mock implements RideRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

RideFlowCubit _makeCubit(
  RideRemoteDataSource rideDataSource,
  SecureSessionService sessionService,
) => RideFlowCubit(
  rideDataSource: rideDataSource,
  sessionService: sessionService,
);

void main() {
  late MockRideRemoteDataSource mockRideRemoteDataSource;
  late MockSecureSessionService mockSessionService;

  setUp(() {
    mockRideRemoteDataSource = MockRideRemoteDataSource();
    mockSessionService = MockSecureSessionService();

    when(
      () => mockSessionService.readDriverId(),
    ).thenAnswer((_) async => 'test-driver-id');

    when(
      () => mockRideRemoteDataSource.acceptRide(
        tripId: any(named: 'tripId'),
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => mockRideRemoteDataSource.updateRideStatus(
        tripId: any(named: 'tripId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => true);
  });

  group('RideFlowCubit — initial state', () {
    test('starts in initial state', () async {
      final cubit = _makeCubit(mockRideRemoteDataSource, mockSessionService);
      expect(cubit.state, isA<RideFlowInitial>());
      expect(cubit.activeRideId, isNull);
      await cubit.close();
    });
  });

  group('RideFlowCubit — acceptRide()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowNavigatingToPickup with correct data',
      build: () => _makeCubit(mockRideRemoteDataSource, mockSessionService),
      act: (cubit) => cubit.acceptRide(
        rideId: 'test-ride-id',
        passengerName: 'Juan Dela Cruz',
        pickupLat: 7.82,
        pickupLng: 123.43,
      ),
      expect: () => [
        const RideFlowNavigatingToPickup(
          passengerName: 'Juan Dela Cruz',
          pickupLat: 7.82,
          pickupLng: 123.43,
        ),
      ],
    );
  });

  group('RideFlowCubit — arriveAtPickup()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowWaitingPassenger starting at 0 seconds',
      build: () => _makeCubit(mockRideRemoteDataSource, mockSessionService),
      act: (cubit) => cubit.arriveAtPickup('Juan Dela Cruz'),
      expect: () => [
        const RideFlowWaitingPassenger(
          passengerName: 'Juan Dela Cruz',
          waitTimeSeconds: 0,
        ),
      ],
    );
  });

  group('RideFlowCubit — startRide()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowInTransit with correct trip data',
      build: () => _makeCubit(mockRideRemoteDataSource, mockSessionService),
      act: (cubit) => cubit.startRide(
        passengerName: 'Juan Dela Cruz',
        destLat: 7.85,
        destLng: 123.45,
        distanceKm: 3.2,
      ),
      expect: () => [
        const RideFlowInTransit(
          passengerName: 'Juan Dela Cruz',
          destLat: 7.85,
          destLng: 123.45,
          distanceKm: 3.2,
        ),
      ],
    );

    test(
      'recovers missing destination coordinates from the active ride',
      () async {
        when(
          () => mockRideRemoteDataSource.getRideStatus('test-ride-id'),
        ).thenAnswer(
          (_) async => {'dropoff_latitude': 7.85, 'dropoff_longitude': 123.45},
        );

        final cubit = _makeCubit(mockRideRemoteDataSource, mockSessionService);
        cubit.resumeRide(
          rideId: 'test-ride-id',
          status: 'arrived',
          passengerName: 'Juan Dela Cruz',
          pickupLat: 7.82,
          pickupLng: 123.43,
        );

        final started = await cubit.startRide(
          passengerName: 'Juan Dela Cruz',
          destLat: null,
          destLng: null,
          distanceKm: 3.2,
          passengerLat: 7.82,
          passengerLng: 123.43,
        );

        expect(started, isTrue);
        expect(
          cubit.state,
          const RideFlowInTransit(
            passengerName: 'Juan Dela Cruz',
            destLat: 7.85,
            destLng: 123.45,
            distanceKm: 3.2,
            passengerLat: 7.82,
            passengerLng: 123.43,
          ),
        );
        verify(
          () => mockRideRemoteDataSource.getRideStatus('test-ride-id'),
        ).called(1);
        await cubit.close();
      },
    );
  });

  group('RideFlowCubit — resumed destination continuity', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'keeps the server destination while waiting for the passenger',
      build: () => _makeCubit(mockRideRemoteDataSource, mockSessionService),
      act: (cubit) => cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'arrived',
        passengerName: 'Juan Dela Cruz',
        pickupLat: 7.82,
        pickupLng: 123.43,
        destLat: 7.85,
        destLng: 123.45,
      ),
      expect: () => [
        const RideFlowWaitingPassenger(
          passengerName: 'Juan Dela Cruz',
          waitTimeSeconds: 0,
          pickupLat: 7.82,
          pickupLng: 123.43,
          destLat: 7.85,
          destLng: 123.45,
        ),
      ],
    );
  });

  group('RideFlowCubit — reset()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'returns to RideFlowInitial from any state',
      build: () => _makeCubit(mockRideRemoteDataSource, mockSessionService),
      seed: () => const RideFlowComplete(fare: 150.0),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<RideFlowInitial>()],
    );
  });
}
