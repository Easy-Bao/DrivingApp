import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('coalesces reads and emits only distinct access states', () async {
    final changes = StreamController<String>();
    final readCompleter = Completer<String>();
    var readCount = 0;
    final monitor = AccessStateMonitor<String>(
      stateChanges: () => changes.stream,
      readState: () {
        readCount++;
        return readCompleter.future;
      },
    );
    final emitted = <String>[];
    final subscription = monitor.changes.listen(emitted.add);

    final start = monitor.start();
    final firstRead = monitor.refresh();
    final secondRead = monitor.refresh();
    expect(readCount, 1);

    readCompleter.complete('ready');
    await start;
    await firstRead;
    await secondRead;
    changes.add('ready');
    changes.add('ready');
    changes.add('service-disabled');
    await Future<void>.delayed(Duration.zero);

    expect(emitted, ['ready', 'service-disabled']);

    await subscription.cancel();
    await changes.close();
    await monitor.dispose();
  });
}
