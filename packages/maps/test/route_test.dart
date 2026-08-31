import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  test('keeps only finite map-ready route coordinates', () {
    const route = Route(
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
      const route = Route(
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

  test('ignores malformed route fields without throwing', () {
    final route = Route.fromJson(const <String, dynamic>{
      'polylinePoints': [
        [123.4, 7.8],
        ['invalid', 7.9],
        {'longitude': 123.5},
        ['123.5', '7.9'],
      ],
      'distance_km': '2.5',
      'duration_seconds': '300',
      'summary': 42,
      'preference': null,
      'profile': null,
    });

    expect(
      route.polylinePoints,
      equals([
        [123.4, 7.8],
        [123.5, 7.9],
      ]),
    );
    expect(route.distanceKm, 2.5);
    expect(route.durationSeconds, 300);
    expect(route.summary, '');
    expect(route.preference, 'fastest');
    expect(route.profile, 'driving');
  });

  test('falls back to the next supported polyline field', () {
    final route = Route.fromJson(const <String, dynamic>{
      'polylinePoints': 'invalid',
      'polyline': [
        [123.4, 7.8],
        [123.5, 7.9],
      ],
    });

    expect(route.polylinePoints, hasLength(2));
  });
}
