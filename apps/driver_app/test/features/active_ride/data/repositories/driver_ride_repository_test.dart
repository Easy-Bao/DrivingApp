import 'package:driver_app/src/features/active_ride/active_ride.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/repositories/driver_ride_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';

class MockRideRemoteDataSource extends Mock implements RideRemoteDataSource {}

class MockRideCounterpartyRemoteDataSource extends Mock
    implements RideCounterpartyRemoteDataSource {}

class MockTelemetryRemoteDataSource extends Mock
    implements TelemetryRemoteDataSource {}

void main() {
  late MockRideRemoteDataSource rideDataSource;
  late MockRideCounterpartyRemoteDataSource counterpartyDataSource;
  late MockTelemetryRemoteDataSource telemetryDataSource;
  late DriverRideRepository repository;

  setUp(() {
    rideDataSource = MockRideRemoteDataSource();
    counterpartyDataSource = MockRideCounterpartyRemoteDataSource();
    telemetryDataSource = MockTelemetryRemoteDataSource();
    repository = DriverRideRepository(
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
}
