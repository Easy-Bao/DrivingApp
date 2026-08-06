import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/location/location_module.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';

void main() {
  test('registers the location gate and manual location routes', () {
    expect(LocationModule.routes, hasLength(3));
    expect(LocationRoutes.gate, isNotEmpty);
    expect(LocationRoutes.country, isNotEmpty);
    expect(LocationRoutes.search, isNotEmpty);
  });
}
