import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('formats client-facing peso amounts with centavo precision and comma grouping', () {
    expect(formatPesoAmount(145.50), '₱145.50');
    expect(formatPesoAmount(10500), '₱10,500.00');
    expect(formatPesoAmount(29.69), '₱29.69');
    expect(formatPesoAmount(25), '₱25.00');
    expect(formatPesoAmount(29.49), '₱29.49');
  });

  test('returns a safe placeholder for non-finite values', () {
    expect(formatPesoAmount(double.nan), '₱—');
    expect(formatPesoAmount(double.infinity), '₱—');
  });

  test('formats negative amounts with a preceding minus sign', () {
    expect(formatPesoAmount(-50.25), '-₱50.25');
    expect(formatPesoAmount(-50), '-₱50.00');
    expect(formatPesoAmount(-29.69), '-₱29.69');
    expect(formatPesoAmount(-29.49), '-₱29.49');
    expect(formatPesoAmount(-0.1), '-₱0.10');
  });
}
