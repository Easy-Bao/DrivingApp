import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  test('destructures canonical and legacy place fields', () {
    final place = Place.fromJson(const {
      'id': 7,
      'name': 'Main Street',
      'address': 'Main Street, Pagadian City',
      'lat': '7.8282',
      'lng': 123.4363,
      'distance_km': 0.4,
      'match_type': 'road',
      'distance_meters': 24.5,
      'confidence': 0.82,
      'context': {'place': 'Pagadian', 'region': 'Zamboanga del Sur'},
    });

    expect(place.id, '7');
    expect(place.fullAddress, 'Main Street, Pagadian City');
    expect(place.latitude, 7.8282);
    expect(place.longitude, 123.4363);
    expect(place.distanceKm, 0.4);
    expect(place.matchType, 'road');
    expect(place.distanceMeters, 24.5);
    expect(place.confidence, 0.82);
    expect(place.context, {'place': 'Pagadian', 'region': 'Zamboanga del Sur'});
    expect(place.displayName, 'Near Main Street');
  });

  test('keeps absent numeric fields at their existing defaults', () {
    final place = Place.fromJson(const {
      'id': 'place-1',
      'name': 'Unknown coordinates',
    });

    expect(place.latitude, 0);
    expect(place.longitude, 0);
    expect(place.distanceKm, isNull);
    expect(place.context, isEmpty);
  });

  test('rejects malformed numeric place fields', () {
    expect(
      () => Place.fromJson(const {'latitude': 'not-a-coordinate'}),
      throwsA(isA<FormatException>()),
    );
  });
}
