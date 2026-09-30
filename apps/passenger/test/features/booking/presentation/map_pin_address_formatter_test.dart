import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/map_pin_address_formatter.dart';

void main() {
  test('prefers city and barangay context over the street address', () {
    const place = Place(
      id: 'rizal-veterans',
      name: 'Rizal Avenue corner Veterans',
      fullAddress:
          'Rizal Avenue corner Veterans, Tetuan, Zamboanga City, Philippines',
      latitude: 6.9214,
      longitude: 122.0790,
      context: {
        'place': 'Zamboanga City',
        'barangay': 'Tetuan',
        'region': 'Zamboanga del Sur',
      },
    );

    expect(formatMapPinSubtitle(place), 'Zamboanga City, Tetuan');
  });

  test('falls back to city and region when barangay is unavailable', () {
    const place = Place(
      id: 'main-street',
      name: 'Main Street',
      fullAddress: 'Main Street, Tuburan, Zamboanga del Sur',
      latitude: 7.8282,
      longitude: 123.4363,
      context: {'place': 'Tuburan', 'region': 'Zamboanga del Sur'},
    );

    expect(formatMapPinSubtitle(place), 'Tuburan, Zamboanga del Sur');
  });
}
