import 'package:flutter_test/flutter_test.dart';
import 'package:location_service/src/features/map/data/repositories/map_native_service_impl.dart';

void main() {
  group('Search Places Tests', () {
    test('searchPlaces returns matching places for query', () async {
      final mapService = MapNativeServiceImpl(
        placeServiceBaseUri: Uri.parse('http://localhost:8089'),
      );

      final result = await mapService.searchPlaces(
        query: 'Resort',
        userLat: 7.8250,
        userLng: 123.4300,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (places) {
          expect(places, isNotNull);
        },
      );
    });
  });
}
