import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('parses finite numeric and string doubles safely', () {
    expect(parseDouble(12), 12.0);
    expect(parseDouble(' 4.25 '), 4.25);
    expect(parseDouble(double.nan, 1.5), 1.5);
    expect(parseDouble('NaN', 1.5), 1.5);
    expect(parseDouble(null, 2.5), 2.5);

    expect(SafeParse.toDouble('3.5'), 3.5);
    expect(SafeParse.toNullableDouble(42), 42.0);
    expect(SafeParse.toNullableDouble('7.5'), 7.5);
    expect(SafeParse.toNullableDouble(double.infinity), isNull);
    expect(SafeParse.toNullableDouble('Infinity'), isNull);
  });
}
