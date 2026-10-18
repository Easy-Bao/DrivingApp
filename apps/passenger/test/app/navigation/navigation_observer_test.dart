import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/app/navigation/navigation_observer.dart';

void main() {
  test(
    'PassengerNavigationObserver emits pop events and closes cleanly',
    () async {
      final observer = PassengerNavigationObserver();
      var popCount = 0;
      final sub = observer.routePopEvents.listen((_) => popCount++);

      final routeA = MaterialPageRoute<void>(builder: (_) => const SizedBox());
      final routeB = MaterialPageRoute<void>(builder: (_) => const SizedBox());

      observer.didPop(routeB, routeA);
      expect(popCount, 1);

      await observer.dispose();
      expect(popCount, 1);

      // After dispose, further didPop calls do not throw or emit
      observer.didPop(routeA, null);
      expect(popCount, 1);

      await sub.cancel();
    },
  );
}
