import 'package:core_models/core_models.dart';
import 'package:test/test.dart';

void main() {
  const goPlaceJson = {
    'id': 'poi-1',
    'name': 'Springland Resort',
    'address': 'Springland Resort Road, Pagadian City',
    'category': 'Resort',
    'lat': 7.8242,
    'lng': 123.4350,
    'distance_km': 0.09,
  };

  const goRouteJson = {
    'originLat': 7.8242,
    'originLng': 123.4350,
    'destLat': 7.8320,
    'destLng': 123.4360,
    'distanceKm': 0.87,
    'durationMin': 1.75,
    'polyline': 'poly_7.8242_123.4350_to_7.8320_123.4360',
    'waypoints': [
      [7.8242, 123.4350],
      [7.8281, 123.4355],
      [7.8320, 123.4360],
    ],
  };

  test('decodes representative Go place JSON', () {
    final place = PlaceModel.fromJson(goPlaceJson);

    expect(place.name, 'Springland Resort');
    expect(place.fullAddress, contains('Pagadian City'));
    expect(place.latitude, 7.8242);
    expect(place.longitude, 123.4350);
    expect(place.distanceKm, 0.09);
  });

  test('decodes representative Go route JSON', () {
    final route = RouteModel.fromJson(goRouteJson);

    expect(route.distanceKm, 0.87);
    expect(route.durationSeconds, 105);
    expect(route.polylinePoints.first, [123.4350, 7.8242]);
    expect(route.polylinePoints.last, [123.4360, 7.8320]);
  });

  test('keeps the intended mobile aliases unchanged', () {
    final place = PlaceModel.fromJson({
      ...goPlaceJson,
      'fullAddress': 'Expected address',
      'latitude': 1.0,
      'longitude': 2.0,
      'distanceKm': 3.0,
    });
    final route = RouteModel.fromJson({
      ...goRouteJson,
      'polylinePoints': [
        [2.0, 1.0],
      ],
      'durationSeconds': 30,
    });

    expect(place.fullAddress, 'Expected address');
    expect(place.latitude, 1.0);
    expect(place.longitude, 2.0);
    expect(place.distanceKm, 3.0);
    expect(route.polylinePoints, [
      [2.0, 1.0],
    ]);
    expect(route.durationSeconds, 30);
  });
}
