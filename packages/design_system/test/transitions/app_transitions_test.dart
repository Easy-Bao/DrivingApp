import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('push transitions enter from their configured side', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final route = PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => const SizedBox.shrink(),
            );
            final animation = const AlwaysStoppedAnimation<double>(0);
            final leftTransition = AppTransitions.push.toLeft.builder(
              route,
              context,
              animation,
              animation,
              const SizedBox.expand(),
            );
            final rightTransition = AppTransitions.push.toRight.builder(
              route,
              context,
              animation,
              animation,
              const SizedBox.expand(),
            );

            return Row(
              children: [
                Expanded(
                  child: KeyedSubtree(
                    key: const ValueKey<String>('left-transition'),
                    child: leftTransition,
                  ),
                ),
                Expanded(
                  child: KeyedSubtree(
                    key: const ValueKey<String>('right-transition'),
                    child: rightTransition,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final leftSlides = tester
        .widgetList<SlideTransition>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('left-transition')),
            matching: find.byType(SlideTransition),
          ),
        )
        .toList();
    final rightSlides = tester
        .widgetList<SlideTransition>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('right-transition')),
            matching: find.byType(SlideTransition),
          ),
        )
        .toList();

    expect(leftSlides.last.position.value, const Offset(1, 0));
    expect(rightSlides.last.position.value, const Offset(-1, 0));
  });
}
