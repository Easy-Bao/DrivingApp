import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return capturedContext;
  }

  testWidgets('uses semantic success tone by default', (tester) async {
    final context = await pumpHost(tester);

    AppSnackBar.show(context, 'Profile updated.');
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, AppSemanticColors.defaults.success);
    expect(snackBar.duration, AppSnackBar.defaultDuration);
    expect(find.byIcon(LucideIcons.circle_check), findsOneWidget);
    expect(find.text('Profile updated.'), findsOneWidget);
  });

  testWidgets('supports info, warning, and error tones', (tester) async {
    final context = await pumpHost(tester);

    AppSnackBar.show(context, 'Ride canceled.', tone: AppSnackBarTone.info);
    await tester.pump();
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      AppTheme.main.colorScheme.inverseSurface,
    );
    expect(find.byIcon(LucideIcons.info), findsOneWidget);

    AppSnackBar.show(
      context,
      'You were switched offline.',
      tone: AppSnackBarTone.warning,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      AppSemanticColors.defaults.warning,
    );
    expect(find.byIcon(LucideIcons.triangle_alert), findsOneWidget);

    AppSnackBar.show(context, 'Could not save.', isError: true);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      AppTheme.main.colorScheme.error,
    );
    expect(find.byIcon(LucideIcons.circle_alert), findsOneWidget);
  });

  testWidgets('extends duration for actions and omits null-callback actions', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    var undone = false;

    AppSnackBar.show(
      context,
      'Notification deleted.',
      tone: AppSnackBarTone.info,
      actionLabel: 'Undo',
      onAction: () => undone = true,
    );
    await tester.pumpAndSettle();

    final withAction = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(withAction.duration, AppSnackBar.actionDuration);
    expect(withAction.action, isNotNull);

    await tester.tap(find.text('Undo'));
    expect(undone, isTrue);

    AppSnackBar.show(context, 'Saved.', actionLabel: 'Undo');
    await tester.pumpAndSettle();

    final withoutCallback = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(withoutCallback.duration, AppSnackBar.defaultDuration);
    expect(withoutCallback.action, isNull);
  });
}
