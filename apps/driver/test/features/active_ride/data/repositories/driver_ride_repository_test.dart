import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/active_ride/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/repositories/driver_ride_repository_impl.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foundation/foundation.dart';

class MockRideRemoteDataSource extends Mock implements RideRemoteDataSource {}

class MockRideCounterpartyRemoteDataSource extends Mock
    implements RideCounterpartyRemoteDataSource {}

class MockTelemetryRemoteDataSource extends Mock
    implements TelemetryRemoteDataSource {}

void main() {
  late MockRideRemoteDataSource rideDataSource;
  late MockRideCounterpartyRemoteDataSource counterpartyDataSource;
  late MockTelemetryRemoteDataSource telemetryDataSource;
  late DriverRideRepositoryImpl repository;

  setUp(() {
    rideDataSource = MockRideRemoteDataSource();
    counterpartyDataSource = MockRideCounterpartyRemoteDataSource();
    telemetryDataSource = MockTelemetryRemoteDataSource();
    repository = DriverRideRepositoryImpl(
      rideDataSource: rideDataSource,
      counterpartyDataSource: counterpartyDataSource,
      telemetryDataSource: telemetryDataSource,
    );
  });

  test('normalizes ride identifiers, coordinates, and fare amount', () async {
    when(() => rideDataSource.getRideStatus('ride-7')).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 7,
        'status': 'IN_TRANSIT',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
        'passenger_id': 12,
        'dropoff_latitude': '7.85',
        'dropoff_longitude': 123.45,
        'fare_amount': '2764',
      },
    );

    final result = await repository.fetchRide('ride-7');

    expect(
      result,
      const Ok<RideSnapshot, Failure>(
        RideSnapshot(
          id: '7',
          status: 'in_transit',
          pickupName: 'Mountain View',
          dropoffName: 'Vista Slope',
          passengerId: '12',
          dropoffLatitude: 7.85,
          dropoffLongitude: 123.45,
          fareAmount: 2764,
        ),
      ),
    );
  });

  test('requires the server arrival response to include its wait timer', () async {
    when(
      () => rideDataSource.markArrived(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'ride-7',
        'status': 'arrived',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
        'arrived_at': '2026-10-04T10:00:00Z',
        'waiting_until': '2026-10-04T10:05:00Z',
      },
    );

    final result = await repository.markArrived(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
    );

    expect(
      result,
      isA<Ok<RideSnapshot, Failure>>(),
    );
    expect(
      result.fold((_) => null, (ride) => ride.waitingUntil),
      DateTime.parse('2026-10-04T10:05:00Z'),
    );
  });

  test('uses dedicated server commands for start and completion', () async {
    when(
      () => rideDataSource.startRide(
        rideId: 'ride-7',
        latitude: 7.82,
        longitude: 123.43,
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'ride-7',
        'status': 'in_transit',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
      },
    );
    when(
      () => rideDataSource.completeRide(
        rideId: 'ride-7',
        latitude: 7.85,
        longitude: 123.45,
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'ride-7',
        'status': 'completed',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
        'fare_amount': 2764,
      },
    );

    final started = await repository.startRide(
      rideId: 'ride-7',
      latitude: 7.82,
      longitude: 123.43,
    );
    final completed = await repository.completeRide(
      rideId: 'ride-7',
      latitude: 7.85,
      longitude: 123.45,
    );

    expect(started.fold((_) => '', (ride) => ride.status), 'in_transit');
    expect(completed.fold((_) => 0, (ride) => ride.fareAmount), 2764);
  });

  test(
    'adapts passenger reads and location cleanup into strict results',
    () async {
      when(() => counterpartyDataSource.fetch('ride-7')).thenAnswer(
        (_) async => {
          'user_id': 'passenger-42',
          'name': 'Passenger',
          'phone': '+639171234567',
          'contact_allowed': true,
        },
      );
      when(() => telemetryDataSource.fetchPassengerLocation('ride-7'))
          .thenAnswer((_) async => {'lat': '7.828', 'lng': '123.434'});
      when(() => telemetryDataSource.removeLocation())
          .thenAnswer((_) async => true);

      final counterpartyResult = await repository.fetchCounterpartyResult(
        'ride-7',
      );
      final locationResult = await repository.fetchPassengerLocationResult(
        'ride-7',
      );
      final cleanupResult = await repository.clearDriverLocationResult();

      expect(counterpartyResult, isA<Ok<RideCounterparty, DomainFailure>>());
      expect(
        locationResult,
        isA<Ok<(double latitude, double longitude)?, DomainFailure>>(),
      );
      expect(cleanupResult, isA<Ok<void, DomainFailure>>());
      expect(
        counterpartyResult.fold((_) => '', (value) => value.userId),
        'passenger-42',
      );
      expect(
        locationResult.fold<(double, double)?>((_) => null, (value) => value),
        (7.828, 123.434),
      );
    },
  );
}
