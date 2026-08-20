import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('DistanceFormatter.fromKilometers', () {
    test('uses metres for distances below one kilometre', () {
      expect(DistanceFormatter.fromKilometers(0.9), '900 m');
      expect(DistanceFormatter.fromKilometers(0.042), '42 m');
    });

    test('uses compact kilometres at and above one kilometre', () {
      expect(DistanceFormatter.fromKilometers(1), '1 km');
      expect(DistanceFormatter.fromKilometers(4.24), '4.2 km');
    });

    test('uses the fallback for missing or invalid values', () {
      expect(DistanceFormatter.fromKilometers(null), '—');
      expect(DistanceFormatter.fromKilometers(-1), '—');
      expect(DistanceFormatter.fromKilometers(double.nan), '—');
    });
  });
}
