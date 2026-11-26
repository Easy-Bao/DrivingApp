import 'dart:math' as math;

import 'package:design_system/design_system.dart'
    show AppPalette, AppStatusColors;
import 'package:material_ui/material_ui.dart';

class TripMapMarkerStyle._() {
  static const double pinIconSize = 1.22;
  static const Color ownLocation = AppPalette.obsidian;
  static const Color tripLocation = AppStatusColors.success;
  static const Color markerSurface = AppPalette.white;
  static const Color labelForeground = AppPalette.obsidian;

  static Color colorFor({required bool isOrigin}) {
    return isOrigin ? ownLocation : tripLocation;
  }
}

class MapMarkerMotion._() {
  static double bearingBetween({
    required double startLatitude,
    required double startLongitude,
    required double targetLatitude,
    required double targetLongitude,
  }) {
    final startLatitudeRad = _radians(startLatitude);
    final targetLatitudeRad = _radians(targetLatitude);
    final longitudeDelta = _radians(targetLongitude - startLongitude);
    final x = math.sin(longitudeDelta) * math.cos(targetLatitudeRad);
    final y =
        math.cos(startLatitudeRad) * math.sin(targetLatitudeRad) -
        math.sin(startLatitudeRad) *
            math.cos(targetLatitudeRad) *
            math.cos(longitudeDelta);
    if (x == 0 && y == 0) return 0;
    return _normalize(math.atan2(x, y) * 180 / math.pi);
  }

  static double interpolateBearing(
    double start,
    double target,
    double progress,
  ) {
    final shortestDelta = _normalize(target - start + 180) - 180;
    return _normalize(start + shortestDelta * progress);
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  static double _normalize(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}
