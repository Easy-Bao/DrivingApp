import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

import 'mock_location_api_client.dart';

void main() {
  group('Search Places Tests', () {
    test('searchPlaces returns matching places for query', () async {
      final mapService = MapNativeService(
        placeServiceBaseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 8089),
        apiClient: MockLocationApiClient(),
      );

      final result = await mapService.searchPlaces(
        query: 'Central',
        userLat: 7.8242,
        userLng: 123.4350,
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (places) {
        expect(places, isNotEmpty);
      });
    });
  });
}
