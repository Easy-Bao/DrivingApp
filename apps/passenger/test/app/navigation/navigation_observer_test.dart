import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/app/navigation/navigation_observer.dart';

void main() {
  test(
    'PassengerNavigationObserver emits pop/removal events and closes cleanly',
    () async {
      final observer = PassengerNavigationObserver();
      var popCount = 0;
      final sub = observer.routePopEvents.listen((_) => popCount++);

      final routeA = MaterialPageRoute<void>(builder: (_) => const SizedBox());
      final routeB = MaterialPageRoute<void>(builder: (_) => const SizedBox());

      observer.didPop(routeB, routeA);
      expect(popCount, 1);

      observer.didRemove(routeB, routeA);
      expect(popCount, 2);

      await observer.dispose();
      expect(popCount, 2);

      observer.didPop(routeA, null);
      observer.didRemove(routeA, null);
      expect(popCount, 2);

      await sub.cancel();
    },
  );
}
