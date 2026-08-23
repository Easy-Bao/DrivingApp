import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('decodes a stable offset page envelope', () {
    final page = OffsetPage<int>.fromJson(const {
      'items': [1, 2],
      'has_more': true,
      'next_offset': 2,
    }, (value) => value! as int);

    expect(page.items, [1, 2]);
    expect(page.hasMore, isTrue);
    expect(page.nextOffset, 2);
  });

  test('rejects inconsistent pagination metadata', () {
    expect(
      () => OffsetPage<int>.fromJson(const {
        'items': <int>[],
        'has_more': true,
        'next_offset': null,
      }, (value) => value! as int),
      throwsFormatException,
    );
    expect(
      () => OffsetPage<int>.fromJson(const {
        'items': <int>[],
        'has_more': false,
        'next_offset': 2,
      }, (value) => value! as int),
      throwsFormatException,
    );
  });
}
