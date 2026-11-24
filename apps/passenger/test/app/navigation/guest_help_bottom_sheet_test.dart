import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/guest_help_bottom_sheet.dart';

void main() {
  testWidgets(
    'shows help actions and emergency notice and returns selected action',
    (tester) async {
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      final resetFuture = showGuestHelpBottomSheet(pageContext);
      await tester.pumpAndSettle();

      expect(find.text('Need help?'), findsOneWidget);
      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('guest-help-emergency-notice')),
        findsOneWidget,
      );
      expect(
        tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
        isFalse,
      );

      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();
      expect(await resetFuture, GuestHelpAction.resetPassword);
      expect(find.text('Need help?'), findsNothing);

      final termsFuture = showGuestHelpBottomSheet(pageContext);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();
      expect(await termsFuture, GuestHelpAction.termsOfService);
    },
  );

  testWidgets('closes cleanly via close button, scrim tap, and downward drag', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final closeFuture = showGuestHelpBottomSheet(pageContext);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('guest-help-close')));
    await tester.pumpAndSettle();
    expect(await closeFuture, isNull);

    final scrimFuture = showGuestHelpBottomSheet(pageContext);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(await scrimFuture, isNull);

    final dragFuture = showGuestHelpBottomSheet(pageContext);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(BottomSheet), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(await dragFuture, isNull);
  });

  testWidgets('renders without overflow on narrow large-text viewports', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final future = showGuestHelpBottomSheet(pageContext);
    await tester.pumpAndSettle();

    expect(find.text('Need help?'), findsOneWidget);
    expect(find.text('Reset password'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey<String>('guest-help-close')));
    await tester.pumpAndSettle();
    expect(await future, isNull);
  });
}
