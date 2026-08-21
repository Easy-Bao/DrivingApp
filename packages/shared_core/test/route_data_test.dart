import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('reads typed extras before query fallbacks', () {
    final data = RoutePayload.from(
      extra: {'distance': ' 12.5 ', 'tipAmount': 30},
      queryParameters: {
        'distance': '9.5',
        'duration': '18 min',
        'tipAmount': '10',
      },
    );

    expect(data.string('distance'), '12.5');
    expect(data.doubleValue('distance'), 12.5);
    expect(data.string('duration'), '18 min');
    expect(data.intValue('tipAmount'), 30);
  });

  test('falls back when an extra is empty or cannot be parsed', () {
    final data = RoutePayload.from(
      extra: {'name': ' ', 'latitude': 'not-a-number'},
      queryParameters: {'name': 'Destination', 'latitude': '7.1'},
    );

    expect(data.string('name'), 'Destination');
    expect(data.doubleValue('latitude'), 7.1);
  });

  test('rejects non-finite numeric route values', () {
    final data = RoutePayload.from(
      extra: {'latitude': double.infinity},
      queryParameters: {'latitude': '7.1'},
    );

    expect(data.doubleValue('latitude'), 7.1);
  });

  test('keeps typed objects available at the route seam', () {
    final destination = Object();
    final data = RoutePayload.from(extra: {'destination': destination});

    expect(data.object<Object>('destination'), same(destination));
    expect(data.object<String>('destination'), isNull);
  });
}
