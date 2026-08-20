import 'package:driver_app/src/features/home/view/widgets/driver_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('driver tab coordinator tracks navigation and back history', () {
    final coordinator = DriverTabNavigationCoordinator();
    addTearDown(coordinator.dispose);

    coordinator.initialize(0);
    expect(coordinator.selectedIndex, 0);
    expect(coordinator.canPop, isTrue);

    coordinator.commit(1);
    coordinator.commit(2);
    expect(coordinator.selectedIndex, 2);
    expect(coordinator.canPop, isFalse);

    expect(coordinator.goBackToPreviousTab(), 1);
    expect(coordinator.goBackToPreviousTab(), 0);
    expect(coordinator.canPop, isTrue);
  });
}
