import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/location/location_module.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';

void main() {
  test('registers only the live location access gate', () {
    expect(LocationModule.routes, hasLength(1));
    expect(LocationRoutes.gate, isNotEmpty);
  });
}
