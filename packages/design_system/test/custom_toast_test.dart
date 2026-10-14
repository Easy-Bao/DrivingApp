import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('replaces an active toast instead of stacking overlays', (
    tester,
  ) async {
    late BuildContext toastContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              toastContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    CustomToast.show(toastContext, 'first message');
    CustomToast.show(toastContext, 'second message');
    await tester.pump();

    expect(find.text('first message'), findsNothing);
    expect(find.text('second message'), findsOneWidget);

    CustomToast.dismiss();
    await tester.pump();
  });

  testWidgets('uses semantic error colors', (tester) async {
    late BuildContext toastContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              toastContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    CustomToast.show(toastContext, 'error', isError: true);
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snackBar.backgroundColor,
      ThemeData(useMaterial3: true).colorScheme.error,
    );

    CustomToast.dismiss();
    await tester.pump();
  });

  testWidgets('does not show a toast while transport is unavailable', (
    tester,
  ) async {
    late BuildContext toastContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppNetworkStatusScope(
            isUnavailable: true,
            child: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    CustomToast.show(toastContext, 'offline toast');
    await tester.pump();

    expect(find.text('offline toast'), findsNothing);
  });
}
