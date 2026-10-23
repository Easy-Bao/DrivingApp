import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

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

  test('decodes cursor pages and rejects mixed continuation modes', () {
    final page = OffsetPage<int>.fromJson(const {
      'items': [1],
      'has_more': true,
      'next_offset': null,
      'next_cursor': 'boundary',
    }, (value) => value! as int);
    expect(page.nextOffset, isNull);
    expect(page.nextCursor, 'boundary');
    final end = OffsetPage<int>.fromJson(const {
      'items': <int>[],
      'has_more': false,
      'next_offset': null,
      'next_cursor': '',
    }, (value) => value! as int);
    expect(end.nextCursor, isNull);
    for (final metadata in [
      {'has_more': true, 'next_cursor': ''},
      {'has_more': false, 'next_cursor': 'boundary'},
      {'has_more': true, 'next_cursor': 123},
      {'has_more': true, 'next_cursor': 'boundary', 'next_offset': 25},
    ]) {
      expect(
        () => OffsetPage<int>.fromJson({
          'items': <int>[],
          ...metadata,
        }, (value) => value! as int),
        throwsFormatException,
      );
    }
  });

  test('decodes only string-keyed JSON objects', () {
    expect(decodeObjectMap(const {'id': 7}), {'id': 7});
    expect(
      () => decodeObjectMap(const ['not an object']),
      throwsFormatException,
    );
    expect(
      () => decodeObjectMap(const {7: 'not a JSON object key'}),
      throwsFormatException,
    );
  });
}
