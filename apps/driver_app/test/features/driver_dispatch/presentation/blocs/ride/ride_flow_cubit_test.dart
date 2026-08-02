import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/data_sources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_state.dart';

class MockTripRemoteDataSource extends Mock implements TripRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

RideFlowCubit _makeCubit(
  TripRemoteDataSource tripRemoteDataSource,
  SecureSessionService sessionService,
) => RideFlowCubit(
  tripRemoteDataSource: tripRemoteDataSource,
  sessionService: sessionService,
);

void main() {
  late MockTripRemoteDataSource mockTripRemoteDataSource;
  late MockSecureSessionService mockSessionService;

  setUp(() {
    mockTripRemoteDataSource = MockTripRemoteDataSource();
    mockSessionService = MockSecureSessionService();

    when(
      () => mockSessionService.readDriverId(),
    ).thenAnswer((_) async => 'test-driver-id');

    when(
      () => mockTripRemoteDataSource.acceptRide(
        tripId: any(named: 'tripId'),
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => mockTripRemoteDataSource.updateRideStatus(
        tripId: any(named: 'tripId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => true);
  });

  group('RideFlowCubit — initial state', () {
    test('starts in initial state', () async {
      final cubit = _makeCubit(mockTripRemoteDataSource, mockSessionService);
      expect(cubit.state, isA<RideFlowInitial>());
      expect(cubit.activeRideId, isNull);
      await cubit.close();
    });
  });

  group('RideFlowCubit — acceptRide()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowEnRoutePickup with correct data',
      build: () => _makeCubit(mockTripRemoteDataSource, mockSessionService),
      act: (cubit) => cubit.acceptRide(
        rideId: 'test-ride-id',
        passengerName: 'Juan Dela Cruz',
        pickupLat: 7.82,
        pickupLng: 123.43,
      ),
      expect: () => [
        const RideFlowEnRoutePickup(
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
      build: () => _makeCubit(mockTripRemoteDataSource, mockSessionService),
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
      build: () => _makeCubit(mockTripRemoteDataSource, mockSessionService),
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
  });

  group('RideFlowCubit — reset()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'returns to RideFlowInitial from any state',
      build: () => _makeCubit(mockTripRemoteDataSource, mockSessionService),
      seed: () => const RideFlowComplete(fare: 150.0),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<RideFlowInitial>()],
    );
  });
}
