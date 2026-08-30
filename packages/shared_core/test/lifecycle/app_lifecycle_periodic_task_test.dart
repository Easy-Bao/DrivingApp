import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('suspends in background and runs one refresh on resume', () async {
    final lifecycleCoordinator = AppLifecycleCoordinator(
      initiallyForeground: false,
    );
    var calls = 0;
    final task = AppLifecyclePeriodicTask(
      lifecycleCoordinator: lifecycleCoordinator,
      interval: const Duration(seconds: 1),
      onTick: () => calls++,
      runImmediately: true,
    );
    addTearDown(() async {
      await task.dispose();
      await lifecycleCoordinator.dispose();
    });

    task.start();
    await Future<void>.delayed(Duration.zero);
    expect(calls, 0);

    lifecycleCoordinator.update(isForeground: true);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);

    lifecycleCoordinator.update(isForeground: false);
    lifecycleCoordinator.update(isForeground: true);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 2);
  });

  test('does not overlap a refresh that is still in flight', () async {
    final lifecycleCoordinator = AppLifecycleCoordinator();
    final firstCall = Completer<void>();
    var calls = 0;
    final task = AppLifecyclePeriodicTask(
      lifecycleCoordinator: lifecycleCoordinator,
      interval: const Duration(milliseconds: 1),
      onTick: () {
        calls++;
        return firstCall.future;
      },
      runImmediately: true,
    );
    addTearDown(() async {
      if (!firstCall.isCompleted) firstCall.complete();
      await task.dispose();
      await lifecycleCoordinator.dispose();
    });

    task.start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 1);

    firstCall.complete();
    await Future<void>.delayed(Duration.zero);
  });
}
