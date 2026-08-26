import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('typing indicator renders and animates three dots', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppChatTypingIndicator(
          bubbleColor: Colors.white,
          dotColor: Colors.black,
          semanticLabel: 'Passenger is typing',
        ),
      ),
    );

    expect(find.bySemanticsLabel('Passenger is typing'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('app-chat-typing-dot-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('app-chat-typing-dot-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('app-chat-typing-dot-2')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 180));
    expect(find.byType(AnimatedBuilder), findsNWidgets(3));
  });

  testWidgets('delivered message transition enters only when enabled', (
    tester,
  ) async {
    var animate = false;

    Widget buildMessage() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: AppChatMessageTransition(
          key: const ValueKey<String>('delivered-message'),
          animate: animate,
          isOutgoing: true,
          child: const Text('Delivered'),
        ),
      );
    }

    await tester.pumpWidget(buildMessage());
    expect(find.text('Delivered'), findsOneWidget);

    animate = true;
    await tester.pumpWidget(buildMessage());
    await tester.pump();

    final transition = tester.widget<FadeTransition>(
      find.byType(FadeTransition),
    );
    expect(transition.opacity.value, lessThan(1));

    await tester.pump(AppChatMessageTransition.defaultDuration);
    final completedTransition = tester.widget<FadeTransition>(
      find.byType(FadeTransition),
    );
    expect(completedTransition.opacity.value, closeTo(1, 0.001));
  });
}
