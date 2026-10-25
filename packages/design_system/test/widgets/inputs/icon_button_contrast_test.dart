import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filled message buttons have a contrasting icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: IconButton.filled(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ),
      ),
    );
    final context = tester.element(find.byIcon(Icons.chat_bubble_outline));
    expect(
      IconTheme.of(context).color,
      Theme.of(context).colorScheme.onPrimary,
    );
  });
}
