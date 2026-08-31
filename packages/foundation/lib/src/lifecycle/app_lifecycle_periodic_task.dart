import 'dart:async';
import 'dart:developer' as dev;

import 'package:foundation/src/lifecycle/app_lifecycle_coordinator.dart';

typedef AppLifecycleTaskCallback = FutureOr<void> Function();

/// Runs one periodic foreground task without creating another platform
/// lifecycle observer in the feature that owns the work.
final class AppLifecyclePeriodicTask {
  final AppLifecycleCoordinator _lifecycleCoordinator;
  final Duration _interval;
  final AppLifecycleTaskCallback _onTick;
  final bool _runImmediately;
  final bool _runImmediatelyOnResume;

  StreamSubscription<AppLifecycleStatus>? _lifecycleSubscription;
  Timer? _timer;
  bool _started = false;
  bool _isRunning = false;

  AppLifecyclePeriodicTask({
    required AppLifecycleCoordinator lifecycleCoordinator,
    required Duration interval,
    required AppLifecycleTaskCallback onTick,
    bool runImmediately = false,
    bool runImmediatelyOnResume = true,
  }) : assert(interval > Duration.zero),
       _lifecycleCoordinator = lifecycleCoordinator,
       _interval = interval,
       _onTick = onTick,
       _runImmediately = runImmediately,
       _runImmediatelyOnResume = runImmediatelyOnResume;

  void start() {
    if (_started) return;
    _started = true;
    _lifecycleSubscription = _lifecycleCoordinator.changes.listen(
      _onLifecycleChanged,
    );
    if (!_lifecycleCoordinator.isForeground) return;
    if (_runImmediately) unawaited(_runTick());
    _schedule();
  }

  void _onLifecycleChanged(AppLifecycleStatus status) {
    if (!_started) return;
    if (status == AppLifecycleStatus.background) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    if (_runImmediatelyOnResume) unawaited(_runTick());
    _schedule();
  }

  void _schedule() {
    if (!_started || !_lifecycleCoordinator.isForeground || _timer != null) {
      return;
    }
    _timer = Timer.periodic(_interval, (_) => unawaited(_runTick()));
  }

  Future<void> _runTick() async {
    if (!_started || !_lifecycleCoordinator.isForeground || _isRunning) {
      return;
    }

    _isRunning = true;
    try {
      await _onTick();
    } catch (error, stackTrace) {
      dev.log(
        'Lifecycle-managed foreground task failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isRunning = false;
    }
  }

  Future<void> dispose() async {
    _started = false;
    _timer?.cancel();
    _timer = null;
    await _lifecycleSubscription?.cancel();
    _lifecycleSubscription = null;
  }
}
