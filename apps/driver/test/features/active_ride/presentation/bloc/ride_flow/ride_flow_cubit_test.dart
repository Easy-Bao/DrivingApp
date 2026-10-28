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

class MockRideRepository extends Mock implements RideRepository {}

class MockSecureSessionService extends Mock implements SessionStore {}

RideFlowCubit _makeCubit(
  RideRepository rideRepository,
  SessionStore sessionService,
) => RideFlowCubit(
  rideRepository: rideRepository,
  sessionService: sessionService,
);

void main() {
  late MockRideRepository mockRideRepository;
  late MockSecureSessionService mockSessionService;

  setUp(() {
    mockRideRepository = MockRideRepository();
    mockSessionService = MockSecureSessionService();

    when(() => mockSessionService.readDriverId())
        .thenAnswer((_) async => 'test-driver-id');
    when(() => mockSessionService.saveActiveRideId(any()))
        .thenAnswer((_) async {});
    when(() => mockSessionService.clearActiveRideId()).thenAnswer((_) async {});
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
        observedAt: any(named: 'observedAt'),
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
        observedAt: any(named: 'observedAt'),
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

  for (final action in ['cancel', 'no-show', 'emergency-stop']) {
    test('rejected $action preserves waiting state and its timer', () async {
      when(
        () => mockRideRepository.cancelRide(
          rideId: any(named: 'rideId'),
          reason: any(named: 'reason'),
          details: any(named: 'details'),
        ),
      ).thenAnswer(
        (_) async => const Err(NetworkFailure('Connection unavailable.')),
      );
      when(() => mockRideRepository.markPassengerNoShow('test-ride-id'))
          .thenAnswer(
            (_) async => const Err(NetworkFailure('Connection unavailable.')),
          );
      when(
        () => mockRideRepository.emergencyStop(
          rideId: any(named: 'rideId'),
          reason: any(named: 'reason'),
          details: any(named: 'details'),
        ),
      ).thenAnswer(
        (_) async => const Err(NetworkFailure('Connection unavailable.')),
      );
      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      addTearDown(cubit.close);
      await cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'arrived',
        passengerName: 'Alex',
        pickupLatitude: 7.82,
        pickupLongitude: 123.43,
        arrivedAt: DateTime.now().toUtc().subtract(const Duration(seconds: 30)),
      );
      final succeeded = await switch (action) {
        'cancel' => cubit.cancelRide(reason: 'vehicle_problem'),
        'no-show' => cubit.markPassengerNoShow(),
        _ => cubit.emergencyStop(reason: 'medical_emergency'),
      };
      expect(succeeded, isFalse);
      expect(cubit.state.isWaitingAtPickup, isTrue);
      expect(cubit.lastActionFailureMessage, isNotEmpty);
      final elapsed = cubit.state.waitTimeSecondsOr(0);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(cubit.state.waitTimeSecondsOr(0), greaterThan(elapsed));
      expect(cubit.activeRideId, 'test-ride-id');
    });
  }

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
        pickupLatitude: 7.82,
        pickupLongitude: 123.43,
      ),
      expect: () => [
        const RideFlowNavigatingToPickup(
          passengerName: 'Juan Dela Cruz',
          pickupLatitude: 7.82,
          pickupLongitude: 123.43,
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
        pickupLatitude: 7.82,
        pickupLongitude: 123.43,
      );
      await acceptStarted.future;

      await cubit.reset();
      releaseAccept.complete(const Ok(null));
      await pendingAccept;

      expect(cubit.state, isA<RideFlowInitial>());
      expect(states.whereType<RideFlowNavigatingToPickup>(), isEmpty);

      await subscription.cancel();
      await cubit.close();
    });
  });

  group('RideFlowCubit — arriveAtPickup()', () {
    final observedAt = DateTime.utc(2026, 10, 11, 10);

    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowWaitingPassenger starting at 0 seconds',
      build: () => _makeCubit(mockRideRepository, mockSessionService),
      act: (cubit) async {
        await cubit.resumeRide(
          rideId: 'test-ride-id',
          status: 'accepted',
          passengerName: 'Juan Dela Cruz',
        );
        await cubit.arriveAtPickup(
          'Juan Dela Cruz',
          driverLatitude: 7.82,
          driverLongitude: 123.43,
          observedAt: observedAt,
        );
      },
      expect: () => [
        const RideFlowNavigatingToPickup(passengerName: 'Juan Dela Cruz'),
        const RideFlowWaitingPassenger(
          passengerName: 'Juan Dela Cruz',
          waitTimeSeconds: 0,
        ),
      ],
      verify: (_) {
        verify(
          () => mockRideRepository.markArrived(
            rideId: 'test-ride-id',
            latitude: 7.82,
            longitude: 123.43,
            observedAt: observedAt,
          ),
        ).called(1);
      },
    );

    test('preserves the repository arrival failure message', () async {
      const message =
          "You must be at the passenger's pickup point to confirm arrival.";
      when(
        () => mockRideRepository.markArrived(
          rideId: 'test-ride-id',
          latitude: 7.82,
          longitude: 123.43,
          observedAt: observedAt,
        ),
      ).thenAnswer((_) async => const Err(ValidationFailure(message)));

      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      await cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'accepted',
        passengerName: 'Juan Dela Cruz',
        pickupLatitude: 7.82,
        pickupLongitude: 123.43,
      );
      await cubit.arriveAtPickup(
        'Juan Dela Cruz',
        driverLatitude: 7.82,
        driverLongitude: 123.43,
        observedAt: observedAt,
      );

      expect(cubit.state, isA<RideFlowNavigatingToPickup>());
      expect(cubit.state.pickupLatitude, 7.82);
      expect(cubit.state.pickupLongitude, 123.43);
      expect(cubit.lastActionFailureMessage, message);
      await cubit.close();
    });
  });

  test(
    'keeps destination and retry state after a rejected completion',
    () async {
      when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
        (_) async => const Err(NetworkFailure('Connection interrupted')),
      );
      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      await cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'in_transit',
        passengerName: 'Passenger',
        destinationLatitude: 7.82,
        destinationLongitude: 123.43,
      );
      final snapshot = cubit.state;
      final fare = await cubit.completeRide(
        driverLatitude: 7.81,
        driverLongitude: 123.42,
      );
      expect(fare, isNull);
      expect(cubit.state, snapshot);
      expect(cubit.lastActionFailureMessage, isNotEmpty);
      expect(cubit.activeRideId, 'test-ride-id');
      await cubit.close();
    },
  );

  group('RideFlowCubit — startRide()', () {
    final observedAt = DateTime.utc(2026, 10, 11, 10);

    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowInTransit with correct trip data',
      build: () => _makeCubit(mockRideRepository, mockSessionService),
      act: (cubit) async {
        await cubit.resumeRide(
          rideId: 'test-ride-id',
          status: 'arrived',
          passengerName: 'Juan Dela Cruz',
        );
        await cubit.startRide(
          passengerName: 'Juan Dela Cruz',
          destinationLatitude: 7.85,
          destinationLongitude: 123.45,
          distanceKm: 3.2,
          driverLatitude: 7.82,
          driverLongitude: 123.43,
          observedAt: observedAt,
        );
      },
      expect: () => [
        const RideFlowWaitingPassenger(
          passengerName: 'Juan Dela Cruz',
          waitTimeSeconds: 0,
        ),
        const RideFlowInTransit(
          passengerName: 'Juan Dela Cruz',
          destinationLatitude: 7.85,
          destinationLongitude: 123.45,
          distanceKm: 3.2,
        ),
      ],
      verify: (_) {
        verify(
          () => mockRideRepository.startRide(
            rideId: 'test-ride-id',
            latitude: 7.82,
            longitude: 123.43,
            observedAt: observedAt,
          ),
        ).called(1);
      },
    );

    test('preserves the repository trip start failure message', () async {
      const message =
          'Your live location is unavailable or out of date. Keep location sharing on and try again.';
      when(
        () => mockRideRepository.startRide(
          rideId: 'test-ride-id',
          latitude: 7.82,
          longitude: 123.43,
          observedAt: observedAt,
        ),
      ).thenAnswer(
        (_) async => const Err(ServerFailure.withStatusCode(message, 503)),
      );

      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      await cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'arrived',
        passengerName: 'Juan Dela Cruz',
      );
      final started = await cubit.startRide(
        passengerName: 'Juan Dela Cruz',
        destinationLatitude: 7.85,
        destinationLongitude: 123.45,
        distanceKm: 3.2,
        driverLatitude: 7.82,
        driverLongitude: 123.43,
        observedAt: observedAt,
      );

      expect(started, isFalse);
      expect(cubit.lastActionFailureMessage, message);
      // The ride is still arrived on the server, so the wait must be retryable.
      expect(cubit.state.isWaitingAtPickup, isTrue);
      expect(cubit.state, isA<RideFlowWaitingPassenger>());
      await cubit.close();
    });

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
        await cubit.resumeRide(
          rideId: 'test-ride-id',
          status: 'arrived',
          passengerName: 'Juan Dela Cruz',
          pickupLatitude: 7.82,
          pickupLongitude: 123.43,
        );

        final started = await cubit.startRide(
          passengerName: 'Juan Dela Cruz',
          destinationLatitude: null,
          destinationLongitude: null,
          distanceKm: 3.2,
          driverLatitude: 7.82,
          driverLongitude: 123.43,
          observedAt: DateTime.utc(2026, 10, 11, 10),
          passengerLatitude: 7.82,
          passengerLongitude: 123.43,
        );

        expect(started, isTrue);
        expect(
          cubit.state,
          const RideFlowInTransit(
            passengerName: 'Juan Dela Cruz',
            destinationLatitude: 7.85,
            destinationLongitude: 123.45,
            distanceKm: 3.2,
            passengerLatitude: 7.82,
            passengerLongitude: 123.43,
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
        pickupLatitude: 7.82,
        pickupLongitude: 123.43,
        destinationLatitude: 7.85,
        destinationLongitude: 123.45,
      ),
      expect: () => [
        const RideFlowWaitingPassenger(
          passengerName: 'Juan Dela Cruz',
          waitTimeSeconds: 0,
          pickupLatitude: 7.82,
          pickupLongitude: 123.43,
          destinationLatitude: 7.85,
          destinationLongitude: 123.45,
        ),
      ],
    );
  });

  test('rejects terminal rides during recovery', () async {
    final cubit = _makeCubit(mockRideRepository, mockSessionService);

    final resumed = await cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'cancelled',
      passengerName: 'Juan Dela Cruz',
    );

    expect(resumed, isFalse);
    expect(cubit.activeRideId, isNull);
    expect(cubit.state, isA<RideFlowError>());
    verify(() => mockSessionService.clearActiveRideId()).called(1);
    await cubit.close();
  });

  test('evicts a ride canceled while the driver was disconnected', () async {
    when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
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
    await cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'accepted',
      passengerName: 'Juan Dela Cruz',
    );

    await cubit.syncAuthoritativeRideState();

    expect(cubit.activeRideId, isNull);
    expect(
      cubit.state,
      const RideFlowTerminal(
        rideId: 'test-ride-id',
        status: 'cancelled',
        message: 'This trip was canceled.',
      ),
    );
    verify(() => mockSessionService.clearActiveRideId()).called(1);
    await cubit.close();
  });

  testWidgets('checks active ride status every 15 seconds', (tester) async {
    when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: 'test-ride-id',
          status: 'accepted',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        ),
      ),
    );
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    await cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'accepted',
      passengerName: 'Juan Dela Cruz',
    );

    await tester.pump(const Duration(seconds: 14));
    verifyNever(() => mockRideRepository.fetchRide('test-ride-id'));

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    verify(() => mockRideRepository.fetchRide('test-ride-id')).called(1);
    await cubit.close();
  });

  test(
    'keeps the active ride after a transient status lookup failure',
    () async {
      when(() => mockRideRepository.fetchRide('test-ride-id'))
          .thenAnswer((_) async => const Err(NetworkFailure('offline')));
      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      await cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'accepted',
        passengerName: 'Juan Dela Cruz',
      );

      await cubit.syncAuthoritativeRideState();

      expect(cubit.activeRideId, 'test-ride-id');
      expect(cubit.state, isA<RideFlowNavigatingToPickup>());
      verifyNever(() => mockSessionService.clearActiveRideId());
      await cubit.close();
    },
  );

  test('evicts a ride completed outside the active flow', () async {
    when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: 'test-ride-id',
          status: 'completed',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        ),
      ),
    );
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    await cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'in_transit',
      passengerName: 'Juan Dela Cruz',
    );

    await cubit.syncAuthoritativeRideState();

    expect(cubit.activeRideId, isNull);
    expect(cubit.state, isA<RideFlowTerminal>());
    expect((cubit.state as RideFlowTerminal).status, 'completed');
    verify(() => mockSessionService.clearActiveRideId()).called(1);
    await cubit.close();
  });

  test(
    'keeps cash settlement active for a completed realtime status',
    () async {
      when(() => mockRideRepository.fetchRide('test-ride-id')).thenAnswer(
        (_) async => const Ok(
          RideSnapshot(
            id: 'test-ride-id',
            status: 'completed',
            pickupName: 'Pickup',
            dropoffName: 'Dropoff',
            fareAmount: 2700,
          ),
        ),
      );
      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      await cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'in_transit',
        passengerName: 'Juan Dela Cruz',
      );

      final fare = await cubit.completeRide(
        driverLatitude: 7.82,
        driverLongitude: 123.43,
      );
      await cubit.handleExternalTerminalRide(
        rideId: 'test-ride-id',
        status: ' COMPLETED ',
      );

      expect(fare, 27);
      expect(cubit.activeRideId, 'test-ride-id');
      expect(cubit.state, isA<RideFlowInTransit>());
      verifyNever(() => mockSessionService.clearActiveRideId());
      await cubit.close();
    },
  );

  test(
    'evicts a ride when the authoritative lookup returns not found',
    () async {
      when(() => mockRideRepository.fetchRide('test-ride-id'))
          .thenAnswer((_) async => const Err(RideNotFoundFailure()));
      final cubit = _makeCubit(mockRideRepository, mockSessionService);
      await cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'accepted',
        passengerName: 'Juan Dela Cruz',
      );

      await cubit.syncAuthoritativeRideState();

      expect(cubit.activeRideId, isNull);
      expect((cubit.state as RideFlowTerminal).status, 'not_found');
      await cubit.close();
    },
  );

  test('keeps no-show unavailable during the clock-skew buffer', () async {
    final now = DateTime.now().toUtc();
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    await cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'arrived',
      passengerName: 'Juan Dela Cruz',
      arrivedAt: now.subtract(const Duration(seconds: 30)),
      waitingUntil: now.subtract(const Duration(seconds: 1)),
    );

    expect(cubit.canMarkPassengerNoShow, isFalse);
    expect(cubit.passengerNoShowTimeRemaining, greaterThan(Duration.zero));
    expect(cubit.state.waitTimeSecondsOr(0), greaterThanOrEqualTo(29));
    await cubit.close();
  });

  test('enables no-show after the buffered server deadline', () async {
    final now = DateTime.now().toUtc();
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    await cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'arrived',
      passengerName: 'Juan Dela Cruz',
      waitingUntil: now.subtract(const Duration(seconds: 10)),
    );

    expect(cubit.canMarkPassengerNoShow, isTrue);
    await cubit.close();
  });

  test('exposes the server-owned no-show time remaining', () async {
    final now = DateTime.now().toUtc();
    final cubit = _makeCubit(mockRideRepository, mockSessionService);
    await cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'arrived',
      passengerName: 'Juan Dela Cruz',
      waitingUntil: now.add(const Duration(seconds: 30)),
    );

    final remaining = cubit.passengerNoShowTimeRemaining;

    expect(remaining, isNotNull);
    expect(remaining!.inSeconds, inInclusiveRange(34, 35));
    await cubit.close();
  });

  group('RideFlowCubit — reset()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'returns to RideFlowInitial from any state',
      build: () => _makeCubit(mockRideRepository, mockSessionService),
      seed: () => const RideFlowInTransit(passengerName: 'Juan Dela Cruz'),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<RideFlowInitial>()],
    );

    test(
      'waits for active ride storage deletion before resetting state',
      () async {
        final deletion = Completer<void>();
        when(() => mockSessionService.clearActiveRideId())
            .thenAnswer((_) => deletion.future);
        final cubit = _makeCubit(mockRideRepository, mockSessionService);
        await cubit.resumeRide(
          rideId: 'test-ride-id',
          status: 'accepted',
          passengerName: 'Juan Dela Cruz',
        );

        final reset = cubit.reset();
        await untilCalled(() => mockSessionService.clearActiveRideId());
        expect(cubit.state, isA<RideFlowNavigatingToPickup>());

        deletion.complete();
        await reset;

        expect(cubit.state, isA<RideFlowInitial>());
        await cubit.close();
      },
    );

    test('clears after a ride ID save already in progress', () async {
      final save = Completer<void>();
      final operations = <String>[];
      when(() => mockSessionService.saveActiveRideId('test-ride-id'))
          .thenAnswer((_) async {
            operations.add('save started');
            await save.future;
            operations.add('save completed');
          });
      when(() => mockSessionService.clearActiveRideId()).thenAnswer((_) async {
        operations.add('clear');
      });
      final cubit = _makeCubit(mockRideRepository, mockSessionService);

      final resume = cubit.resumeRide(
        rideId: 'test-ride-id',
        status: 'accepted',
        passengerName: 'Juan Dela Cruz',
      );
      await untilCalled(
        () => mockSessionService.saveActiveRideId('test-ride-id'),
      );
      final reset = cubit.reset();

      expect(operations, ['save started']);
      save.complete();
      expect(await resume, isFalse);
      await reset;

      expect(operations, ['save started', 'save completed', 'clear']);
      expect(cubit.state, isA<RideFlowInitial>());
      await cubit.close();
    });
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
    await cubit.resumeRide(
      rideId: 'test-ride-id',
      status: 'accepted',
      passengerName: 'Juan Dela Cruz',
    );

    final cancelled = await cubit.cancelRide(reason: 'vehicle_problem');

    expect(cancelled, isTrue);
    expect(cubit.activeRideId, isNull);
    expect(cubit.state, isA<RideFlowInitial>());
    verify(() => mockSessionService.clearActiveRideId()).called(1);
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
    await cubit.resumeRide(
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
    verify(() => mockSessionService.clearActiveRideId()).called(1);
    await cubit.close();
  });
}
