import 'package:flutter_test/flutter_test.dart';
import 'package:location_service/src/features/map/data/repositories/map_native_service_impl.dart';

void main() {
  group('Reverse Geocode Tests', () {
    test('reverseGeocode returns place model for valid coordinates', () async {
      final mapService = MapNativeServiceImpl(
        placeServiceBaseUri: Uri.parse('http://localhost:8089'),
      );

      final result = await mapService.reverseGeocode(
        lat: 7.8242,
        lng: 123.4350,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (place) {
          expect(place.name, isNotEmpty);
          expect(place.name, isNot(equals('Unknown location')));
        },
      );
    });
  });
}
