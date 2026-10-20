import 'package:driver/src/presentation/formatters/driver_value_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fareInPesos', () {
    test('converts cent-denominated trip values to pesos', () {
      expect(fareInPesos({'fare_amount': 2500}), 25);
      expect(fareInPesos({'offered_fare': 3175}), 31.75);
      expect(fareInPesos({'proposed_fare': 4200}), 42);
    });

    test('supports legacy peso values and rejects non-finite values', () {
      expect(fareInPesos({'fare': 29.5}), 29.5);
      expect(fareInPesos({'fare_amount': double.infinity}), isNull);
      expect(fareInPesos({}), isNull);
    });
  });

  test('normalizes dynamic values and applies sentence-case fallbacks', () {
    expect(valueAsString('  ride-42  '), 'ride-42');
    expect(valueAsString('  '), isNull);
    expect(valueAsString(null), isNull);
    expect(sentenceCase('  IN_TRANSIT '), 'In_transit');
    expect(sentenceCase(null, 'Past trip'), 'Past trip');
  });
}
