import 'package:driver_app/src/features/location/location_module.dart';
import 'package:driver_app/src/features/location/location_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers one live location access gate', () {
    expect(DriverLocationModule.routes, hasLength(1));
    expect(DriverLocationRoutes.gate, isNotEmpty);
  });
}
