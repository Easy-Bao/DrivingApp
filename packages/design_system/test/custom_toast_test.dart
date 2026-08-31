import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('replaces an active toast instead of stacking overlays', (
    tester,
  ) async {
    late BuildContext toastContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            toastContext = context;
            return const SizedBox.shrink();
          },
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
        theme: EasyRideTheme.light,
        home: Builder(
          builder: (context) {
            toastContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    CustomToast.show(toastContext, 'error', isError: true);
    await tester.pump();

    final toastContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(MaterialApp),
            matching: find.byType(Container),
          )
          .last,
    );
    final decoration = toastContainer.decoration! as BoxDecoration;
    expect(decoration.color, EasyRideTheme.light.colorScheme.errorContainer);

    CustomToast.dismiss();
    await tester.pump();
  });
}
