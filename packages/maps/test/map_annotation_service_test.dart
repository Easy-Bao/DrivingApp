import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  test('trip markers keep one screen-space size and role colors', () {
    expect(TripMapMarkerStyle.pinIconSize, greaterThan(1.0));
    expect(
      TripMapMarkerStyle.colorFor(isOrigin: true),
      const Color(0xFF100E11),
    );
    expect(
      TripMapMarkerStyle.colorFor(isOrigin: false),
      const Color(0xFF198754),
    );
  });
}
