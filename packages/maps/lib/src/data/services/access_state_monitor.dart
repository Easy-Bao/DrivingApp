import 'dart:async';

typedef AccessStateStream<T> = Stream<T> Function();
typedef AccessStateReader<T> = Future<T> Function();

/// Coalesces access reads and deduplicates native service state updates.
final class AccessStateMonitor<T>({
  required this._stateChanges,
  required this._readState,
}) {
  this;

  final AccessStateStream<T> _stateChanges;
  final AccessStateReader<T> _readState;
  final _changesController = StreamController<T>.broadcast();

  StreamSubscription<T>? _stateSubscription;
  Future<T>? _refreshInFlight;
  T? _lastState;
  int _eventVersion = 0;
  bool _disposed = false;

  Stream<T> get changes => _changesController.stream;

  Future<T> start() async {
    if (_disposed) {
      throw StateError('AccessStateMonitor has been disposed.');
    }
    _stateSubscription ??= _stateChanges().listen(
      _handleStreamEvent,
      onError: (_, _) => unawaited(_refreshAfterStreamError()),
    );
    return refresh();
  }

  Future<T> refresh() {
    if (_disposed) {
      throw StateError('AccessStateMonitor has been disposed.');
    }
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final refresh = _readAndPublish();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    });
  }

  void _handleStreamEvent(T state) {
    if (_disposed) return;
    _eventVersion++;
    _publish(state);
  }

  Future<T> _readAndPublish() async {
    final readVersion = _eventVersion;
    final state = await _readState();
    if (_disposed) return state;
    if (_eventVersion != readVersion) {
      return _lastState ?? state;
    }
    _publish(state);
    return state;
  }

  Future<void> _refreshAfterStreamError() async {
    if (_disposed) return;
    try {
      await refresh();
    } catch (_) {
      // A native stream error is reconciled by the next explicit refresh.
    }
  }

  void _publish(T state) {
    if (_disposed || _lastState == state || _changesController.isClosed) return;
    _lastState = state;
    _changesController.add(state);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _changesController.close();
  }
}
