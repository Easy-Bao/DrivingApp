import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unwinds history and avoids redundant notifications on root tab', () {
    final coordinator = TabNavigationCoordinator();
    var notifications = 0;
    coordinator.addListener(() => notifications += 1);

    coordinator.initialize(0);
    expect(coordinator.selectedIndex, 0);
    expect(coordinator.canPop, isTrue);

    expect(coordinator.goBackToPreviousTab(), 0);
    expect(notifications, 0);

    coordinator.commit(2);
    coordinator.commit(1);
    expect(notifications, 2);
    expect(coordinator.canPop, isFalse);

    expect(coordinator.goBackToPreviousTab(), 2);
    expect(coordinator.goBackToPreviousTab(), 0);
    expect(coordinator.canPop, isTrue);
    expect(notifications, 4);

    expect(coordinator.goBackToPreviousTab(), 0);
    expect(notifications, 4);

    coordinator.dispose();
  });
}
