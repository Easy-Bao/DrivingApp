import 'package:flutter_test/flutter_test.dart';
import 'package:location_service/src/features/map/data/repositories/map_native_service_impl.dart';

void main() {
  group('Get Nearby Locations Tests', () {
    test('getNearbyPois returns list of places for given coordinates', () async {
      final mapService = MapNativeServiceImpl(
        placeServiceBaseUri: Uri.parse('http://localhost:8089'),
      );

      final result = await mapService.getNearbyPois(
        lat: 7.8250,
        lng: 123.4300,
        page: 1,
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
