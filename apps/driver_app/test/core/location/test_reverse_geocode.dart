import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/src/core/location/location.dart';

import 'mock_location_api_client.dart';

void main() {
  group('Reverse Geocode Tests', () {
    test('reverseGeocode returns place model for valid coordinates', () async {
      final mapService = MapNativeService(
        placeServiceBaseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 8089),
        apiClient: MockLocationApiClient(),
      );

      final result = await mapService.reverseGeocode(
        lat: 7.8242,
        lng: 123.4350,
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (place) {
        expect(place.name, isNotEmpty);
        expect(place.name, isNot(equals('Unknown location')));
      });
    });
  });
}
