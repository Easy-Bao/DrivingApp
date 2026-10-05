import 'dart:async';

import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:foundation/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';

class MockDriverRideRepository extends Mock implements DriverRideRepository {}

class MockSecureSessionService extends Mock implements DriverSessionStore {}

RideFlowCubit _makeCubit(
  DriverRideRepository rideRepository,
  DriverSessionStore sessionService,
) => RideFlowCubit(
  rideRepository: rideRepository,
  sessionService: sessionService,
);

void main() {
  late MockDriverRideRepository mockRideRepository;
  late MockSecureSessionService mockSessionService;

  setUp(() {
    mockRideRepository = MockDriverRideRepository();
    mockSessionService = MockSecureSessionService();

    when(() => mockSessionService.readDriverId())
        .thenAnswer((_) async => 'test-driver-id');
    when(() => mockSessionService.saveActiveRideId(any()))
        .thenAnswer((_) async {});
    when(() => mockSessionService.readActiveRideId())
        .thenAnswer((_) async => null);

    when(
      () => mockRideRepository.acceptRide(
        rideId: any(named: 'rideId'),
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    when(
      () => mockRideRepository.markArrived(
        rideId: any(named: 'rideId'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: 'test-ride-id',
          status: 'arrived',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        ),
      ),
    );

    when(
      () => mockRideRepository.startRide(
        rideId: any(named: 'rideId'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: 'test-ride-id',
          status: 'in_transit',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        ),
      ),
    );
  });

  group('RideFlowCubit — initial state', () {
    test('starts in initial state', () async {
      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      expect(cubit.state, isA<RideFlowInitial>());
      expect(cubit.activeRideId, isNull);
      await cubit.close();
    });
  });

  group('RideFlowCubit — acceptRide()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowNavigatingToPickup with correct data',
      build: () => _makeCubit(mockRideRepository, mockSessionService),
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

    test('ignores a late accept result after the ride flow resets', () async {
      final acceptStarted = Completer<void>();
      final releaseAccept = Completer<Result<void, Failure>>();
      when(
        () => mockRideRepository.acceptRide(
          rideId: any(named: 'rideId'),
          driverId: any(named: 'driverId'),
        ),
      ).thenAnswer((_) {
        acceptStarted.complete();
        return releaseAccept.future;
      });

      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      final states = <RideFlowState>[];
      final subscription = cubit.stream.listen(states.add);
      final pendingAccept = cubit.acceptRide(
        rideId: 'test-ride-id',
        passengerName: 'Juan Dela Cruz',
        pickupLat: 7.82,
        pickupLng: 123.43,
      );
      await acceptStarted.future;

      cubit.reset();
      releaseAccept.complete(const Ok(null));
      await pendingAccept;

      expect(cubit.state, isA<RideFlowInitial>());
      expect(states.whereType<RideFlowNavigatingToPickup>(), isEmpty);

      await subscription.cancel();
      await cubit.close();
    });
  });

  group('RideFlowCubit — arriveAtPickup()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowWaitingPassenger starting at 0 seconds',
      build: () => _makeCubit(mockRideRepository, mockSessionService),
      act: (cubit) async {
        cubit.resumeRide(
          rideId: 'test-ride-id',
          status: 'accepted',
          passengerName: 'Juan Dela Cruz',
        );
        await cubit.arriveAtPickup(
          'Juan Dela Cruz',
          driverLat: 7.82,
          driverLng: 123.43,
        );
      },
      expect: () => [
        const RideFlowNavigatingToPickup(passengerName: 'Juan Dela Cruz'),
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
      build: () => _makeCubit(mockRideRepository, mockSessionService),
      act: (cubit) async {
        cubit.resumeRide(
          rideId: 'test-ride-id',
          status: 'arrived',
          passengerName: 'Juan Dela Cruz',
        );
        await cubit.startRide(
          passengerName: 'Juan Dela Cruz',
          destLat: 7.85,
          destLng: 123.45,
          distanceKm: 3.2,
          driverLat: 7.82,
          driverLng: 123.43,
        );
      },
      expect: () => [
        const RideFlowWaitingPassenger(
          passengerName: 'Juan Dela Cruz',
          waitTimeSeconds: 0,
        ),
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
        when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
          (_) async => const Ok(
            RideSnapshot(
              id: 'test-ride-id',
              status: 'arrived',
              pickupName: 'Pickup',
              dropoffName: 'Dropoff',
              dropoffLatitude: 7.85,
              dropoffLongitude: 123.45,
            ),
          ),
        );

        final cubit = _makeCubit(mockRideRepository, mockSessionService);
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
          driverLat: 7.82,
          driverLng: 123.43,
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
        verify(() => mockRideRepository.fetchRide('test-ride-id')).called(1);
        await cubit.close();
      },
    );
  });

  group('RideFlowCubit — resumed destination continuity', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'keeps the server destination while waiting for the passenger',
      build: () => _makeCubit(mockRideRepository, mockSessionService),
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

  test('rejects terminal rides during recovery', () async {
    final cubit = _makeCubit(mockRideRepository, mockSessionService);

    final resumed = cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'cancelled',
      passengerName: 'Juan Dela Cruz',
    );

    expect(resumed, isFalse);
    expect(cubit.activeRideId, isNull);
    expect(cubit.state, isA<RideFlowError>());
    verify(() => mockSessionService.saveActiveRideId('')).called(1);
    await cubit.close();
  });

  test('restores a completed ride that still needs a cash outcome', () async {
    when(() => mockSessionService.readActiveRideId())
        .thenAnswer((_) async => 'test-ride-id');
    when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: 'test-ride-id',
          status: 'completed',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
          fareAmount: 3000,
          paymentStatus: 'unpaid',
          cashOutcome: 'unpaid',
        ),
      ),
    );

    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    final ride = await cubit.restorePendingCashSettlement();

    expect(ride?.id, 'test-ride-id');
    expect(cubit.activeRideId, 'test-ride-id');
    expect(cubit.state, const RideFlowComplete(fare: 30));
    verify(() => mockRideRepository.fetchRide('test-ride-id')).called(1);
    await cubit.close();
  });

  test(
    'clears a cached ride after its cash outcome was already recorded',
    () async {
      when(() => mockSessionService.readActiveRideId())
          .thenAnswer((_) async => 'test-ride-id');
      when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
        (_) async => Ok(
          RideSnapshot(
            id: 'test-ride-id',
            status: 'completed',
            pickupName: 'Pickup',
            dropoffName: 'Dropoff',
            fareAmount: 3000,
            paymentStatus: 'unpaid',
            cashOutcome: 'unpaid',
            cashReceivedAt: DateTime.utc(2026, 10, 5),
          ),
        ),
      );

      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      final ride = await cubit.restorePendingCashSettlement();

      expect(ride, isNull);
      expect(cubit.activeRideId, isNull);
      verify(() => mockSessionService.saveActiveRideId('')).called(1);
      await cubit.close();
    },
  );

  test(
    'keeps an active cached ride available for normal trip recovery',
    () async {
      when(() => mockSessionService.readActiveRideId())
          .thenAnswer((_) async => 'test-ride-id');
      when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
        (_) async => const Ok(
          RideSnapshot(
            id: 'test-ride-id',
            status: 'in_transit',
            pickupName: 'Pickup',
            dropoffName: 'Dropoff',
            fareAmount: 3000,
          ),
        ),
      );

      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      final ride = await cubit.restorePendingCashSettlement();

      expect(ride, isNull);
      verifyNever(() => mockSessionService.saveActiveRideId(''));
      await cubit.close();
    },
  );

  test(
    'uses the server arrival deadline after resuming a waiting ride',
    () async {
      final now = DateTime.now().toUtc();
      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'arrived',
        passengerName: 'Juan Dela Cruz',
        arrivedAt: now.subtract(const Duration(seconds: 30)),
        waitingUntil: now.subtract(const Duration(seconds: 1)),
      );

      expect(cubit.canMarkPassengerNoShow, isTrue);
      expect(cubit.state.waitTimeSecondsOr(0), greaterThanOrEqualTo(29));
      await cubit.close();
    },
  );

  test('exposes the server-owned no-show time remaining', () async {
    final now = DateTime.now().toUtc();
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'arrived',
      passengerName: 'Juan Dela Cruz',
      waitingUntil: now.add(const Duration(seconds: 30)),
    );

    final remaining = cubit.passengerNoShowTimeRemaining;

    expect(remaining, isNotNull);
    expect(remaining!.inSeconds, inInclusiveRange(29, 30));
    await cubit.close();
  });

  group('RideFlowCubit — reset()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'returns to RideFlowInitial from any state',
      build: () => _makeCubit(mockRideRepository, mockSessionService),
      seed: () => const RideFlowComplete(fare: 150.0),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<RideFlowInitial>()],
    );
  });

  test('cancels the server ride and clears the active flow', () async {
    when(
      () => mockRideRepository.cancelRide(
        rideId: 'test-ride-id',
        reason: 'vehicle_problem',
        details: '',
      ),
    ).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: 'test-ride-id',
          status: 'cancelled',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        ),
      ),
    );
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'accepted',
      passengerName: 'Juan Dela Cruz',
    );

    final cancelled = await cubit.cancelRide(reason: 'vehicle_problem');

    expect(cancelled, isTrue);
    expect(cubit.activeRideId, isNull);
    expect(cubit.state, isA<RideFlowInitial>());
    verify(() => mockSessionService.saveActiveRideId('')).called(1);
    await cubit.close();
  });

  test('ends the server ride for safety and clears the active flow', () async {
    when(
      () => mockRideRepository.emergencyStop(
        rideId: 'test-ride-id',
        reason: 'accident',
        details: 'Minor collision.',
      ),
    ).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: 'test-ride-id',
          status: 'cancelled',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        ),
      ),
    );
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'in_transit',
      passengerName: 'Juan Dela Cruz',
    );

    final stopped = await cubit.emergencyStop(
      reason: 'accident',
      details: 'Minor collision.',
    );

    expect(stopped, isTrue);
    expect(cubit.activeRideId, isNull);
    expect(cubit.state, isA<RideFlowInitial>());
    verify(() => mockSessionService.saveActiveRideId('')).called(1);
    await cubit.close();
  });

  test('records a partial cash outcome without treating it as paid', () async {
    when(
      () => mockRideRepository.settleCash(
        rideId: 'test-ride-id',
        cashReceivedAmount: 1500,
        cashChangeAmount: 0,
        cashOutcome: 'partial',
      ),
    ).thenAnswer((_) async => const Ok(3000));
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'in_transit',
      passengerName: 'Juan Dela Cruz',
    );

    final fare = await cubit.confirmCashPayment(
      cashReceivedAmount: 1500,
      cashChangeAmount: 0,
      cashOutcome: 'partial',
    );

    expect(fare, 30.0);
    verify(
      () => mockRideRepository.settleCash(
        rideId: 'test-ride-id',
        cashReceivedAmount: 1500,
        cashChangeAmount: 0,
        cashOutcome: 'partial',
      ),
    ).called(1);
    await cubit.close();
  });
}
