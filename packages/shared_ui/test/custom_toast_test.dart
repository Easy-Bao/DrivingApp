import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

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
}
