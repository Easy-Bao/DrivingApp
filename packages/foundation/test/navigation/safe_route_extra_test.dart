import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  group('SafeRouteExtra', () {
    test('extracts finite numbers and falls back on NaN or Infinity', () {
      final map = <String, dynamic>{
        'nan': double.nan,
        'inf': double.infinity,
        'negInf': double.negativeInfinity,
        'validDouble': 12.5,
        'validInt': 7,
        'stringDouble': '3.14',
        'stringInt': '42',
        'nested': {'a': 1},
      };

      expect(SafeRouteExtra.getDouble(map, 'nan', 1.5), 1.5);
      expect(SafeRouteExtra.getDouble(map, 'inf', 1.5), 1.5);
      expect(SafeRouteExtra.getDouble(map, 'validDouble'), 12.5);
      expect(SafeRouteExtra.getDouble(map, 'stringDouble'), 3.14);

      expect(SafeRouteExtra.getInt(map, 'nan', 9), 9);
      expect(SafeRouteExtra.getInt(map, 'negInf', 9), 9);
      expect(SafeRouteExtra.getInt(map, 'validInt'), 7);
      expect(SafeRouteExtra.getInt(map, 'stringInt'), 42);

      expect(SafeRouteExtra.getString(map, 'nested', 'fallback'), 'fallback');
      expect(SafeRouteExtra.getString(map, 'validInt'), '7');
    });

    test('asMap returns empty map for non-string-keyed maps', () {
      expect(SafeRouteExtra.asMap({1: 'bad'}), isEmpty);
      expect(SafeRouteExtra.asMap({'ok': true}), {'ok': true});
      expect(SafeRouteExtra.asMap(null), isEmpty);
    });
  });
}
