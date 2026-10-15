import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('shows a non-interactive semantic status when unavailable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox.expand(),
                AppNetworkStatusBanner(isVisible: true, isActiveTracking: true),
              ],
            ),
          ),
        ),
      );

      expect(
        find.text('Connection unavailable. Retrying automatically.'),
        findsOneWidget,
      );
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(TextButton), findsNothing);
      expect(
        tester.widget<Material>(find.byType(Material).last).color,
        Theme.of(tester.element(find.byType(Material).last))
            .colorScheme
            .tertiaryContainer,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('renders an actionable error across the top system edge', (
    tester,
  ) async {
    var retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              AppStatusBanner(
                isVisible: true,
                message: "Couldn't connect. Try again.",
                tone: AppStatusBannerTone.error,
                actionLabel: 'Try again',
                onAction: () => retryCount++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("Couldn't connect. Try again."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(retryCount, 1);
  });

  testWidgets('stays hidden outside active tracking', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SizedBox.expand(),
              AppNetworkStatusBanner(isVisible: true, isActiveTracking: false),
            ],
          ),
        ),
      ),
    );

    expect(
      find.text('Connection unavailable. Retrying automatically.'),
      findsNothing,
    );
  });

  testWidgets('shares unavailable state with route-level surfaces', (
    tester,
  ) async {
    bool? isUnavailable;
    await tester.pumpWidget(
      MaterialApp(
        home: AppNetworkStatusScope(
          isUnavailable: true,
          child: Builder(
            builder: (context) {
              isUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(isUnavailable, isTrue);
  });

  testWidgets(
    'hides page-owned error surfaces while transport is unavailable',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppNetworkStatusScope(
            isUnavailable: true,
            child: Column(
              children: [
                AppStatusBanner(
                  isVisible: true,
                  message: 'Connection failed',
                  tone: AppStatusBannerTone.error,
                ),
                AppErrorBanner(message: 'Connection failed', onRetry: _noop),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Connection failed'), findsNothing);
    },
  );
}

void _noop() {}
