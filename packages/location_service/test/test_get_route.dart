import 'package:flutter_test/flutter_test.dart';
import 'package:location_service/src/features/map/data/repositories/map_native_service_impl.dart';

void main() {
  group('Get Route Tests', () {
    test('getRoute returns route model for origin and destination', () async {
      final mapService = MapNativeServiceImpl(
        placeServiceBaseUri: Uri.parse('http://localhost:8089'),
      );

      final result = await mapService.getRoute(
        originLat: 7.8242,
        originLng: 123.4350,
        destLat: 7.8320,
        destLng: 123.4360,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (route) {
          expect(route.distanceKm, greaterThan(0));
          expect(route.polylinePoints, isNotEmpty);
        },
      );
    });
  });
}
