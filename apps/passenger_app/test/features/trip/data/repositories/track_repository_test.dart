import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip/data/datasources/ride_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/repositories/track_repository.dart';
import 'package:shared_core/shared_core.dart';

class MockRideRemoteDataSource extends Mock implements RideRemoteDataSource {}

void main() {
  late MockRideRemoteDataSource dataSource;
  late TrackRepository repository;

  setUp(() {
    dataSource = MockRideRemoteDataSource();
    repository = TrackRepository(remoteDataSource: dataSource);
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
}
