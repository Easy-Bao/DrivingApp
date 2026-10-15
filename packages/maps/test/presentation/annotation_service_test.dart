import 'package:design_system/design_system.dart'
    show EasyRidePalette, EasyRideStatusColors;
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  test('trip markers keep one screen-space size and role colors', () {
    expect(TripMapMarkerStyle.pinIconSize, greaterThan(1.0));
    expect(
      TripMapMarkerStyle.colorFor(isOrigin: true),
      EasyRidePalette.obsidian,
    );
    expect(
      TripMapMarkerStyle.colorFor(isOrigin: false),
      EasyRideStatusColors.success,
    );
  });

  test('marker motion follows the shortest bearing arc', () {
    expect(
      MapMarkerMotion.interpolateBearing(350, 10, 0.5),
      closeTo(0, 0.0001),
    );
    expect(
      MapMarkerMotion.bearingBetween(
        startLat: 7.8,
        startLng: 123.4,
        targetLat: 7.8,
        targetLng: 123.5,
      ),
      closeTo(89.99, 0.5),
    );
  });
}
