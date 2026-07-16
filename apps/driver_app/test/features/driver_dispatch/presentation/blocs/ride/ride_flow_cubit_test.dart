import 'package:core_models/core_models.dart';
import 'package:driver_services/driver_services.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/ride/ride_flow_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/ride/ride_flow_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

//TODO: Fix and hide localhost url
class MockRideRepo extends Mock implements RideRepository {}

class MockTripApiService extends Mock implements TripApiService {
  @override
  Uri get baseUrl => Uri.parse('http://localhost:8080');
}

RideFlowCubit _makeCubit(RideRepository repo, TripApiService apiService) =>
    RideFlowCubit(repository: repo, apiService: apiService);

void main() {
  late MockRideRepo repo;
  late MockTripApiService mockApiService;

  setUp(() {
    repo = MockRideRepo();
    mockApiService = MockTripApiService();

    // Register active mock calls for API updates
    when(
      () => mockApiService.acceptRide(
        rideId: any(named: 'rideId'),
        driverId: any(named: 'driverId'),
        driverName: any(named: 'driverName'),
        driverRating: any(named: 'driverRating'),
        vehicleType: any(named: 'vehicleType'),
        plateNumber: any(named: 'plateNumber'),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => mockApiService.updateRideStatus(any(), any()),
    ).thenAnswer((_) async => true);
  });

  group('RideFlowCubit — initial state', () {
    test('starts in initial state', () async {
      final cubit = _makeCubit(repo, mockApiService);
      expect(cubit.state, isA<RideFlowInitial>());
      expect(cubit.activeRideId, isNull);
      await cubit.close();
    });
  });

  group('RideFlowCubit — acceptRide()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'emits RideFlowEnRoutePickup with correct data',
      build: () => _makeCubit(repo, mockApiService),
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
      build: () => _makeCubit(repo, mockApiService),
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
      build: () => _makeCubit(repo, mockApiService),
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
          (_) async => const Right(
            FareResult(
              baseFare: 40.0,
              distanceCharge: 25.6,
              timeCharge: 8.0,
              surgeCharge: 0.0,
              totalFare: 73.6,
            ),
          ),
        );
        return _makeCubit(repo, mockApiService);
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
        ).thenAnswer(
          (_) async => const Left(ServerFailure('fare computation failed')),
        );
        return _makeCubit(repo, mockApiService);
      },
      act: (cubit) => cubit.endRide(distanceKm: 3.2, durationMinutes: 8.0),
      expect: () => [const RideFlowComplete(fare: 50.0)],
    );
  });

  group('RideFlowCubit — reset()', () {
    blocTest<RideFlowCubit, RideFlowState>(
      'returns to RideFlowInitial from any state',
      build: () => _makeCubit(repo, mockApiService),
      seed: () => const RideFlowComplete(fare: 150.0),
      act: (cubit) => cubit.reset(),
      expect: () => [isA<RideFlowInitial>()],
    );
  });
}
