class const OffsetPage<T>({
  required this.items,
  required this.hasMore,
  required this.nextOffset,
}) {
  final List<T> items;
  final bool hasMore;
  final int? nextOffset;

  factory OffsetPage.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) decodeItem,
  ) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Page response is missing an items list.');
    }
    final rawHasMore = json['has_more'];
    if (rawHasMore is! bool) {
      throw const FormatException('Page response is missing has_more.');
    }
    final rawNextOffset = json['next_offset'];
    if (rawNextOffset != null && (rawNextOffset is! int || rawNextOffset < 0)) {
      throw const FormatException('Page response has an invalid next offset.');
    }
    final nextOffset = rawNextOffset as int?;
    if ((rawHasMore && nextOffset == null) ||
        (!rawHasMore && nextOffset != null)) {
      throw const FormatException(
        'Page response has inconsistent pagination metadata.',
      );
    }
    return OffsetPage<T>(
      items: rawItems.map(decodeItem).toList(growable: false),
      hasMore: rawHasMore,
      nextOffset: nextOffset,
    );
  }
}

Map<String, dynamic> decodeObjectMap(
  Object? value, {
  String message = 'Expected a JSON object.',
}) {
  if (value is! Map) {
    throw FormatException(message);
  }

  final decoded = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException(message);
    }
    decoded[entry.key as String] = entry.value;
  }
  return decoded;
}
