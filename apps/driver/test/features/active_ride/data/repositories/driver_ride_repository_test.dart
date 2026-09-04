import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/active_ride/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/repositories/driver_ride_repository_impl.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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

  test('normalizes ride identifiers, coordinates, and centavo fare', () async {
    when(() => rideDataSource.getRideStatus('ride-7')).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 7,
        'status': 'IN_TRANSIT',
        'pickup_name': 'Mountain View',
        'dropoff_name': 'Vista Slope',
        'passenger_id': 12,
        'dropoff_latitude': '7.85',
        'dropoff_longitude': 123.45,
        'fare_centavos': '2764',
      },
    );

    final result = await repository.fetchRide('ride-7');

    expect(
      result,
      const Right<Failure, RideSnapshot>(
        RideSnapshot(
          id: '7',
          status: 'in_transit',
          pickupName: 'Mountain View',
          dropoffName: 'Vista Slope',
          passengerId: '12',
          dropoffLatitude: 7.85,
          dropoffLongitude: 123.45,
          fareCentavos: 2764,
        ),
      ),
    );
  });

  test('serializes the typed in-transit status for the transport', () async {
    when(
      () => rideDataSource.updateRideStatus(
        tripId: 'ride-7',
        status: 'in_transit',
      ),
    ).thenAnswer((_) async => true);

    final result = await repository.updateRideStatus(
      rideId: 'ride-7',
      status: RideStatus.inTransit,
    );

    expect(result, const Right<Failure, void>(null));
    verify(
      () => rideDataSource.updateRideStatus(
        tripId: 'ride-7',
        status: 'in_transit',
      ),
    ).called(1);
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
