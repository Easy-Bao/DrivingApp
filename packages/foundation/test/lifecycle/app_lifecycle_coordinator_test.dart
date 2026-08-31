import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('starts in the foreground and emits only real transitions', () async {
    final coordinator = AppLifecycleCoordinator();
    final statuses = <AppLifecycleStatus>[];
    final subscription = coordinator.changes.listen(statuses.add);
    addTearDown(() async {
      await subscription.cancel();
      await coordinator.dispose();
    });

    expect(coordinator.isForeground, isTrue);

    coordinator.update(isForeground: true);
    coordinator.update(isForeground: false);
    coordinator.update(isForeground: false);
    coordinator.update(isForeground: true);

    expect(statuses, [
      AppLifecycleStatus.background,
      AppLifecycleStatus.foreground,
    ]);
    expect(coordinator.isForeground, isTrue);
  });
}
