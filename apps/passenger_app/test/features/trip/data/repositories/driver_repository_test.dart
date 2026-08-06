import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/location/repositories/map_native_service.dart';
import 'package:passenger_app/src/core/location/services/map_provider.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/repositories/driver_repository.dart';
import 'package:shared_core/shared_core.dart';

class MockBiddingRemoteDataSource extends Mock
    implements BiddingRemoteDataSource {}

class MatrixLocationApiClient extends LocationApiClient {
  MatrixLocationApiClient() : super(Dio());

  @override
  Future<Map<String, dynamic>> getTravelMatrix({
    required Map<String, dynamic> body,
  }) async {
    return {
      'distancesKm': [0.0],
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await MapProvider.initialize(
      nativeService: MapNativeService(
        placeServiceBaseUri: Uri.parse('http://test.invalid'),
        apiClient: MatrixLocationApiClient(),
      ),
    );
  });

  test(
    'connects an online driver to a passenger at the same location',
    () async {
      const latitude = 7.828;
      const longitude = 123.434;
      final dataSource = MockBiddingRemoteDataSource();

      when(() => dataSource.fetchOnlineDrivers()).thenAnswer(
        (_) async => [
          {
            'id': 42,
            'name': 'Nearby Driver',
            'vehicle_type': 'Sedan',
            'plate_number': 'ABC 1234',
            'rating': 4.8,
          },
        ],
      );
      when(
        () => dataSource.fetchNearbyDrivers(
          latitude: latitude,
          longitude: longitude,
        ),
      ).thenAnswer(
        (_) async => [
          {'driver_id': '42', 'latitude': latitude, 'longitude': longitude},
        ],
      );

      final result = await DriverRepository(
        biddingDataSource: dataSource,
      ).getNearbyDrivers(lat: latitude, lng: longitude);

      expect(result.isRight(), isTrue);
      final drivers = result.getOrElse((_) => const []);
      expect(drivers, hasLength(1));
      expect(drivers.single.id, '42');
      expect(drivers.single.lat, latitude);
      expect(drivers.single.lng, longitude);
      expect(drivers.single.distanceKm, 0.0);
      verify(() => dataSource.fetchOnlineDrivers()).called(1);
      verify(
        () => dataSource.fetchNearbyDrivers(
          latitude: latitude,
          longitude: longitude,
        ),
      ).called(1);
    },
  );
}
