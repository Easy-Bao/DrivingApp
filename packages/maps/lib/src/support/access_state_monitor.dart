import 'dart:async';

typedef AccessStateStream<T> = Stream<T> Function();
typedef AccessStateReader<T> = Future<T> Function();

/// Coalesces access reads and deduplicates native service state updates.
///
/// The monitor contains no platform dependency; each client supplies its
/// location adapter, so passenger and driver share lifecycle behavior without
/// sharing app-specific state enums.
final class AccessStateMonitor<T>({
  required AccessStateStream<T> stateChanges,
  required AccessStateReader<T> readState,
}) {
  this : _stateChanges = stateChanges, _readState = readState;

  final AccessStateStream<T> _stateChanges;
  final AccessStateReader<T> _readState;
  final _changesController = StreamController<T>.broadcast();

  StreamSubscription<T>? _stateSubscription;
  Future<T>? _refreshInFlight;
  T? _lastState;

  Stream<T> get changes => _changesController.stream;

  Future<T> start() async {
    _stateSubscription ??= _stateChanges().listen(
      _publish,
      onError: (_, _) => unawaited(_refreshAfterStreamError()),
    );
    return refresh();
  }

  Future<T> refresh() {
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

  Future<T> _readAndPublish() async {
    final state = await _readState();
    _publish(state);
    return state;
  }

  Future<void> _refreshAfterStreamError() async {
    try {
      await refresh();
    } catch (_) {
      // A native stream error is reconciled by the next explicit refresh.
    }
  }

  void _publish(T state) {
    if (_lastState == state || _changesController.isClosed) return;
    _lastState = state;
    _changesController.add(state);
  }

  Future<void> dispose() async {
    await _stateSubscription?.cancel();
    await _changesController.close();
  }
}
