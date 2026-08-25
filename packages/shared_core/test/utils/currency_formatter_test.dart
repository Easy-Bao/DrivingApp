import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test(
    'rounds client-facing peso amounts without changing domain precision',
    () {
      expect(formatPesoAmount(29.69), '₱30');
      expect(formatPesoAmount(25), '₱25');
      expect(formatPesoAmount(29.49), '₱29');
    },
  );

  test('returns a safe placeholder for non-finite values', () {
    expect(formatPesoAmount(double.nan), '₱—');
    expect(formatPesoAmount(double.infinity), '₱—');
  });
}
