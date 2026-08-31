import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/src/core/location/location.dart';

import 'mock_location_api_client.dart';

void main() {
  group('Get Route Tests', () {
    test('getRoute returns route model for origin and destination', () async {
      final mapService = MapNativeService(
        placeServiceBaseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 8089),
        apiClient: MockLocationApiClient(),
      );

      final result = await mapService.getRoute(
        originLat: 7.8242,
        originLng: 123.4350,
        destLat: 7.8300,
        destLng: 123.4400,
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (route) {
        expect(route.polylinePoints, isNotEmpty);
        expect(route.distanceKm, greaterThan(0));
      });
    });
  });
}
