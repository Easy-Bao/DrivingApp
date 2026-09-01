typedef CacheClock = DateTime Function();

/// Shares in-flight work and briefly reuses successful values.
///
/// Errors are never retained. Callers can also opt out of caching a resolved
/// value, which is useful for nullable results where `null` means a transient
/// failure.
class AsyncTtlCache<K, V>({
  required this.ttl,
  required this.maxEntries,
  CacheClock? clock,
}) {
  final Duration ttl;
  final int maxEntries;
  final CacheClock _clock;
  final Map<K, _AsyncTtlCacheEntry<V>> _values = {};
  final Map<K, _AsyncTtlCacheRequest<V>> _inFlight = {};
  int _generation = 0;

  this
    : assert(ttl > Duration.zero),
      assert(maxEntries > 0),
      _clock = clock ?? DateTime.now;

  Future<V> getOrLoad(
    K key,
    Future<V> Function() loader, {
    bool Function(V value)? shouldCache,
  }) async {
    final cached = _read(key);
    if (cached != null) return cached.value;

    final ongoingRequest = _inFlight[key]?.future;
    if (ongoingRequest != null) return ongoingRequest;

    final request = loader();
    final pendingRequest = _AsyncTtlCacheRequest(request);
    _inFlight[key] = pendingRequest;
    final requestGeneration = _generation;
    try {
      final value = await request;
      if (requestGeneration == _generation &&
          (shouldCache?.call(value) ?? true)) {
        _store(key, value);
      }
      return value;
    } finally {
      if (identical(_inFlight[key], pendingRequest)) {
        _inFlight.remove(key);
      }
    }
  }

  void clear() {
    _generation++;
    _values.clear();
    _inFlight.clear();
  }

  _AsyncTtlCacheEntry<V>? _read(K key) {
    final entry = _values[key];
    if (entry == null) return null;

    final expiresAt = entry.createdAt.add(ttl);
    if (!_clock().isBefore(expiresAt)) {
      _values.remove(key);
      return null;
    }
    return entry;
  }

  void _store(K key, V value) {
    _values[key] = _AsyncTtlCacheEntry(value: value, createdAt: _clock());
    while (_values.length > maxEntries) {
      late K oldestKey;
      var hasOldest = false;
      DateTime? oldestCreatedAt;

      for (final entry in _values.entries) {
        if (!hasOldest || entry.value.createdAt.isBefore(oldestCreatedAt!)) {
          oldestKey = entry.key;
          oldestCreatedAt = entry.value.createdAt;
          hasOldest = true;
        }
      }

      if (!hasOldest) return;
      _values.remove(oldestKey);
    }
  }
}

class const _AsyncTtlCacheEntry<V>({
  required this.value,
  required this.createdAt,
}) {
  final V value;
  final DateTime createdAt;
}

class const _AsyncTtlCacheRequest<V>(this.future) {
  final Future<V> future;
}
