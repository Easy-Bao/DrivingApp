import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:passenger/src/features/active_ride/data/repositories/track_repository_impl.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';

class MockRideRemoteDataSource extends Mock implements RideRemoteDataSource {}

void main() {
  late MockRideRemoteDataSource dataSource;
  late TrackRepository repository;

  setUp(() {
    dataSource = MockRideRemoteDataSource();
    repository = TrackRepositoryImpl(remoteDataSource: dataSource);
  });

  test(
    'parses the numeric driver identifier returned by the ride API',
    () async {
      when(() => dataSource.fetchRide('303')).thenAnswer(
        (_) async => {
          'id': 303,
          'status': 'accepted',
          'driver_id': 42,
          'driver_name': 'Nearby Driver',
          'plate_number': 'ABC 1234',
          'vehicle_type': 'Bao Bao',
        },
      );

      final result = await repository.getRideStatusUpdate('303');

      expect(result.isRight(), isTrue);
      final update = result.getOrElse(
        (_) => const RideUpdate(status: RideStatus.unknown),
      );
      expect(update.driverId, '42');
      expect(update.status, RideStatus.accepted);
    },
  );

  test('parses the realtime service latitude and longitude fields', () async {
    when(() => dataSource.fetchDriverLocation('303')).thenAnswer(
      (_) async => {'driver_id': '42', 'latitude': 7.828, 'longitude': 123.434},
    );

    final result = await repository.fetchDriverLocation('303');

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => (0.0, 0.0)), (7.828, 123.434));
  });

  test('adapts ride detail reads into strict domain results', () async {
    when(() => dataSource.fetchRide('303')).thenAnswer(
      (_) async => {
        'id': '303',
        'status': 'completed',
        'pickup_name': 'Pickup',
        'dropoff_name': 'Dropoff',
      },
    );
    when(() => dataSource.fetchCounterparty('303')).thenAnswer(
      (_) async => {
        'user_id': '42',
        'name': 'Nearby Driver',
        'phone': '+639171234567',
        'contact_allowed': true,
      },
    );

    final rideResult = await repository.fetchRideResult('303');
    final counterpartyResult = await repository.fetchCounterpartyResult('303');

    expect(rideResult, isA<Ok<RideSnapshot, DomainFailure>>());
    expect(counterpartyResult, isA<Ok<RideCounterparty, DomainFailure>>());
    expect(rideResult.fold((_) => '', (value) => value.id), '303');
    expect(counterpartyResult.fold((_) => '', (value) => value.userId), '42');
  });
}
