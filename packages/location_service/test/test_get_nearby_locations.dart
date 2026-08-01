import 'package:flutter_test/flutter_test.dart';
import 'package:location_service/location_service.dart';

import 'mock_location_api_client.dart';

void main() {
  group('Get Nearby Locations Tests', () {
    test('getNearbyPois returns list of places for given coordinates', () async {
      final mapService = MapNativeService(
        placeServiceBaseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 8089),
        apiClient: MockLocationApiClient(),
      );

      final result = await mapService.getNearbyPois(
        lat: 7.8242,
        lng: 123.4350,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (places) {
          expect(places, isNotEmpty);
        },
      );
    });
  });
}
