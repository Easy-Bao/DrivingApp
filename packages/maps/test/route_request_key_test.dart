import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  test(
    'normalizes coordinate noise while keeping routing options distinct',
    () {
      final fastest = RouteRequestKey(
        originLat: 7.82420001,
        originLng: 123.43500001,
        destLat: 7.83000001,
        destLng: 123.44000001,
        preference: RoutePreference.fastest,
        profile: RouteProfile.driving,
        excludePoints: const [],
      );
      final sameRequest = RouteRequestKey(
        originLat: 7.82420002,
        originLng: 123.43500002,
        destLat: 7.83000002,
        destLng: 123.44000002,
        preference: RoutePreference.fastest,
        profile: RouteProfile.driving,
        excludePoints: const [],
      );
      final shortest = RouteRequestKey(
        originLat: 7.8242,
        originLng: 123.4350,
        destLat: 7.8300,
        destLng: 123.4400,
        preference: RoutePreference.shortest,
        profile: RouteProfile.driving,
        excludePoints: const [],
      );

      expect(fastest, sameRequest);
      expect(fastest, isNot(shortest));
    },
  );
}
