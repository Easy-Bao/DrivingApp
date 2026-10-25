import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('accepts a pasted six-digit code and supports OTP autofill', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: AppVerificationCodeField(
            controller: controller,
            focusNode: focus,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'a12b34567');
    await tester.pump();
    expect(controller.text, '123456');
    expect(submitted, isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).autofillHints,
      contains(AutofillHints.oneTimeCode),
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, '123456');
    controller.clear();
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('fits six digits and an error on a narrow large-text layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TextEditingController(text: '123456');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: AppVerificationCodeField(
              controller: controller,
              focusNode: focus,
              errorText: 'Enter a valid code.',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Enter a valid code.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
