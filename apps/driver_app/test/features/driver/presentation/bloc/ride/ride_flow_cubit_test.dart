import 'package:driver_app/features/driver/data/repositories/ride_repository.dart';
import 'package:driver_app/features/driver/presentation/bloc/ride/ride_flow_cubit.dart';
import 'package:driver_app/features/driver/presentation/bloc/ride/ride_flow_state.dart';
import 'package:driver_app/src/rust/models/fare_models.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRideRepo extends Mock implements RideRepository {}

RideFlowCubit _makeCubit(RideRepository repo) =>
    RideFlowCubit(repository: repo);

void main() {
  late MockRideRepo repo;

  setUp(() => repo = MockRideRepo());

  group('RideFlowCubit — initial state', () {
    test('initial state is Idle', () async {
      final cubit = _makeCubit(repo);
      expect(cubit.state, isA<RideFlowInitial>());
      await cubit.close();
    });
  });

  group('RideFlowCubit — acceptRide()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowEnRoutePickup with correct data',
      build: () => _makeCubit(repo),
      act: (cubit) => cubit.acceptRide(
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
      build: () => _makeCubit(repo),
      act: (cubit) => cubit.arriveAtPickup('Juan Dela Cruz'),
      expect: () => [
        const RideFlowWaitingPassenger(
          passengerName: 'Juan Dela Cruz',
          waitTimeSeconds: 0,
        ),
        // The timer fires every 1s but bloc_test stops after act completes.
        // Integration-level timer behaviour is tested separately.
      ],
    );
  });

  group('RideFlowCubit — startRide()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowInTransit with correct trip data',
      build: () => _makeCubit(repo),
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

  group('RideFlowCubit — endRide()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowComplete with fare from repository on success',
      build: () {
        when(
          () => repo.getFare(
            distanceKm: any(named: 'distanceKm'),
            durationMinutes: any(named: 'durationMinutes'),
          ),
        ).thenAnswer(
          (_) async => const FareResult(
            baseFare: 40.0,
            distanceCharge: 25.6,
            timeCharge: 8.0,
            surgeCharge: 0.0,
            totalFare: 73.6,
          ),
        );
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.endRide(distanceKm: 3.2, durationMinutes: 8.0),
      expect: () => [const RideFlowComplete(fare: 73.6)],
    );

    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowComplete with fallback fare on repository error',
      build: () {
        when(
          () => repo.getFare(
            distanceKm: any(named: 'distanceKm'),
            durationMinutes: any(named: 'durationMinutes'),
          ),
        ).thenThrow(Exception('fare computation failed'));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.endRide(distanceKm: 3.2, durationMinutes: 8.0),
      expect: () => [const RideFlowComplete(fare: 50.0)],
    );
  });

  group('RideFlowCubit — reset()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'returns to RideFlowInitial from any state',
      build: () => _makeCubit(repo),
      seed: () => const RideFlowComplete(fare: 150.0),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<RideFlowInitial>()],
    );
  });
}
