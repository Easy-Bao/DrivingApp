import 'package:driver/src/presentation/formatters/driver_value_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('driverFareInPesos', () {
    test('converts cent-denominated trip values to pesos', () {
      expect(driverFareInPesos({'fare_amount': 2500}), 25);
      expect(driverFareInPesos({'offered_fare': 3175}), 31.75);
      expect(driverFareInPesos({'proposed_fare': 4200}), 42);
    });

    test('supports legacy peso values and rejects non-finite values', () {
      expect(driverFareInPesos({'fare': 29.5}), 29.5);
      expect(driverFareInPesos({'fare_amount': double.infinity}), isNull);
      expect(driverFareInPesos({}), isNull);
    });
  });

  test('normalizes dynamic values and applies sentence-case fallbacks', () {
    expect(driverValueAsString('  ride-42  '), 'ride-42');
    expect(driverValueAsString('  '), isNull);
    expect(driverValueAsString(null), isNull);
    expect(driverSentenceCase('  IN_TRANSIT '), 'In_transit');
    expect(driverSentenceCase(null, 'Past trip'), 'Past trip');
  });
}
