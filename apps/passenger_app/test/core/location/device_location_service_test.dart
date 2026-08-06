import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/location/services/device_location_service.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  tearDown(LocationService.clearManualLocation);

  test(
    'manual pickup locations provide coordinates without device telemetry',
    () {
      const place = PlaceModel(
        id: 'manual-1',
        name: 'BaoRide Plaza',
        fullAddress: 'BaoRide Plaza, Philippines',
        latitude: 6.9214,
        longitude: 122.0790,
      );

      LocationService.setManualLocation(place);

      expect(LocationService.hasManualLocation, isTrue);
      expect(LocationService.manualPlace, same(place));
      expect(LocationService.lastPosition?.latitude, place.latitude);
      expect(LocationService.lastPosition?.longitude, place.longitude);
      expect(LocationService.lastPosition?.isMocked, isTrue);
    },
  );
}
