import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('returns true on confirm and false on cancel', (tester) async {
    bool? lastResult;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                lastResult = await showAppConfirmDialog(
                  context,
                  title: 'Log out?',
                  message: 'You will need to sign in again.',
                  confirmLabel: 'Log out',
                  cancelLabel: 'Cancel',
                  icon: LucideIcons.log_out,
                  tone: AppConfirmDialogTone.destructive,
                  isDestructive: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    final confirmButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(
      confirmButton.style?.backgroundColor?.resolve({}),
      AppTheme.main.colorScheme.error,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(lastResult, isFalse);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(lastResult, isTrue);
  });

  testWidgets('blocks back dismissal when barrierDismissible is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                unawaited(
                  showAppConfirmDialog(
                    context,
                    title: 'Trip canceled',
                    message: 'This trip is no longer active.',
                    confirmLabel: 'Back to dispatch',
                    barrierDismissible: false,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope>(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.byType(PopScope),
      ),
    );
    expect(popScope.canPop, isFalse);
  });
}
