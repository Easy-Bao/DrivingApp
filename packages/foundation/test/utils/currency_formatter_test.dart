import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

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

  test('formats negative amounts with a preceding minus sign', () {
    expect(formatPesoAmount(-50), '-₱50');
    expect(formatPesoAmount(-29.69), '-₱30');
    expect(formatPesoAmount(-29.49), '-₱29');
    expect(formatPesoAmount(-0.1), '₱0');
  });
}
