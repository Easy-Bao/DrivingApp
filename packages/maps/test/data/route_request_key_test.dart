import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  test(
    'normalizes coordinate noise while keeping routing options distinct',
    () {
      final fastest = RouteRequestKey(
        originLatitude: 7.82420001,
        originLongitude: 123.43500001,
        destinationLatitude: 7.83000001,
        destinationLongitude: 123.44000001,
        preference: RoutePreference.fastest,
        profile: RouteProfile.driving,
        excludePoints: const [],
      );
      final sameRequest = RouteRequestKey(
        originLatitude: 7.82420002,
        originLongitude: 123.43500002,
        destinationLatitude: 7.83000002,
        destinationLongitude: 123.44000002,
        preference: RoutePreference.fastest,
        profile: RouteProfile.driving,
        excludePoints: const [],
      );
      final shortest = RouteRequestKey(
        originLatitude: 7.8242,
        originLongitude: 123.4350,
        destinationLatitude: 7.8300,
        destinationLongitude: 123.4400,
        preference: RoutePreference.shortest,
        profile: RouteProfile.driving,
        excludePoints: const [],
      );

      expect(fastest, sameRequest);
      expect(fastest, isNot(shortest));
    },
  );
}
