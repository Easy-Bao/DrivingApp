import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('keeps only finite map-ready route coordinates', () {
    const route = RouteModel(
      polylinePoints: [
        [123.4, 7.8],
        [double.nan, 7.9],
        [123.5, 7.9],
        [123.6, 95.0],
      ],
      distanceKm: 2,
      durationSeconds: 300,
    );

    expect(
      route.validPolylinePoints,
      equals([
        [123.4, 7.8],
        [123.5, 7.9],
      ]),
    );
    expect(route.hasGeometry, isTrue);
    expect(route.startCoordinate, (lat: 7.8, lng: 123.4));
  });

  test(
    'reports route geometry as unavailable when fewer than two points remain',
    () {
      const route = RouteModel(
        polylinePoints: [
          [123.4, 7.8],
          [123.5, 95.0],
        ],
        distanceKm: 2,
        durationSeconds: 300,
      );

      expect(
        route.validPolylinePoints,
        equals([
          [123.4, 7.8],
        ]),
      );
      expect(route.hasGeometry, isFalse);
      expect(route.startCoordinate, (lat: 7.8, lng: 123.4));
    },
  );
}
