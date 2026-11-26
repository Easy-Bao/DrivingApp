import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

class _StatefulProbe extends StatefulWidget {
  const _StatefulProbe();

  @override
  State<_StatefulProbe> createState() => _StatefulProbeState();
}

class _StatefulProbeState extends State<_StatefulProbe> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final isUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
    return Scaffold(
      body: Column(
        children: [
          Text('offline:$isUnavailable'),
          Text('count:$count'),
          TextButton(
            onPressed: () => setState(() => count++),
            child: const Text('Increment'),
          ),
          AppErrorBanner(message: 'Inline failure', onRetry: () {}),
        ],
      ),
    );
  }
}

void main() {
  testWidgets(
    'propagates offline state, shows banner, and preserves child state across transitions',
    (tester) async {
      final coordinator = NetworkAvailabilityCoordinator(failureThreshold: 1);
      addTearDown(coordinator.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: AppNetworkStatusHost(
            coordinator: coordinator,
            child: const _StatefulProbe(),
          ),
        ),
      );

      expect(find.text('offline:false'), findsOneWidget);
      expect(find.text('Inline failure'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('app-network-status-banner')),
        findsNothing,
      );

      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);

      coordinator.recordFailure();
      await tester.pump();

      expect(find.text('offline:true'), findsOneWidget);
      expect(find.text('count:1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('app-network-status-banner')),
        findsOneWidget,
      );
      expect(
        find.text('No internet connection. Reconnecting automatically...'),
        findsOneWidget,
      );
      expect(find.text('Inline failure'), findsNothing);

      coordinator.recordSuccess();
      await tester.pump();

      expect(find.text('offline:false'), findsOneWidget);
      expect(find.text('count:1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('app-network-status-banner')),
        findsNothing,
      );
      expect(find.text('Inline failure'), findsOneWidget);
    },
  );
}
