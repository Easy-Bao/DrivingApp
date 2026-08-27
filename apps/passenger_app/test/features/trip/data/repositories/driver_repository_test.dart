import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip/data/datasources/driver_discovery_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/repositories/driver_repository.dart';
import 'package:shared_core/shared_core.dart';

class MockDriverDiscoveryRemoteDataSource extends Mock
    implements DriverDiscoveryRemoteDataSource {}

class MockLocationApiClient extends Mock implements ILocationApiClient {}

void main() {
  test(
    'connects an online driver to a passenger at the same location',
    () async {
      const latitude = 7.828;
      const longitude = 123.434;
      final dataSource = MockDriverDiscoveryRemoteDataSource();
      final locationApiClient = MockLocationApiClient();

      when(() => dataSource.fetchOnlineDrivers(any())).thenAnswer(
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
      when(
        () => locationApiClient.getTravelMatrix(body: any(named: 'body')),
      ).thenAnswer(
        (_) async => {
          'distances_km': [0.0],
          'durations_min': [1.0],
        },
      );

      final result = await DriverRepository(
        discoveryDataSource: dataSource,
        locationApiClient: locationApiClient,
      ).getNearbyDrivers(lat: latitude, lng: longitude);

      expect(result.isRight(), isTrue);
      final drivers = result.getOrElse((_) => const []);
      expect(drivers, hasLength(1));
      expect(drivers.single.id, '42');
      expect(drivers.single.lat, latitude);
      expect(drivers.single.lng, longitude);
      expect(drivers.single.distanceKm, 0.0);
      verify(() => dataSource.fetchOnlineDrivers(any())).called(1);
      verify(
        () => dataSource.fetchNearbyDrivers(
          latitude: latitude,
          longitude: longitude,
        ),
      ).called(1);
    },
  );

  test(
    'coalesces concurrent lookups and normalizes server field types',
    () async {
      const latitude = 7.828;
      const longitude = 123.434;
      final dataSource = MockDriverDiscoveryRemoteDataSource();
      final locationApiClient = MockLocationApiClient();
      final onlineDrivers = Completer<List<Map<String, dynamic>>>();
      final nearbyDrivers = Completer<List<Map<String, dynamic>>>();

      when(
        () => dataSource.fetchOnlineDrivers(any()),
      ).thenAnswer((_) => onlineDrivers.future);
      when(
        () => dataSource.fetchNearbyDrivers(
          latitude: latitude,
          longitude: longitude,
        ),
      ).thenAnswer((_) => nearbyDrivers.future);
      when(
        () => locationApiClient.getTravelMatrix(body: any(named: 'body')),
      ).thenAnswer(
        (_) async => {
          'distances_km': [0.0],
          'durations_min': [1.0],
        },
      );

      final repository = DriverRepository(
        discoveryDataSource: dataSource,
        locationApiClient: locationApiClient,
      );
      final firstLookup = repository.getNearbyDrivers(
        lat: latitude,
        lng: longitude,
      );
      final secondLookup = repository.getNearbyDrivers(
        lat: latitude,
        lng: longitude,
      );

      onlineDrivers.complete([
        {
          'id': '42',
          'name': 'Nearby Driver',
          'vehicle_type': 'Sedan',
          'plate_number': 'ABC 1234',
          'rating': '4.8',
          'onboard_passenger_count': '2',
        },
      ]);
      nearbyDrivers.complete([
        {'driverId': 42, 'lat': '7.828', 'lng': '123.434'},
      ]);

      final results = await Future.wait([firstLookup, secondLookup]);

      expect(results[0].isRight(), isTrue);
      expect(results[1].isRight(), isTrue);
      final drivers = results[0].getOrElse((_) => const []);
      expect(drivers.single.id, '42');
      expect(drivers.single.rating, 4.8);
      expect(drivers.single.onboardPassengerCount, 2);
      verify(() => dataSource.fetchOnlineDrivers(any())).called(1);
      verify(
        () => dataSource.fetchNearbyDrivers(
          latitude: latitude,
          longitude: longitude,
        ),
      ).called(1);
    },
  );
}
