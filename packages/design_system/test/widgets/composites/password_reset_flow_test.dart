import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'separates code and password entry and preserves the draft on back',
    (tester) async {
      String? submittedCode;
      String? submittedPassword;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: AppPasswordResetFlow(
            email: 'person@example.com',
            minimumPasswordLength: 8,
            onBack: () {},
            onResend: () {},
            onSubmit: (code, password) {
              submittedCode = code;
              submittedPassword = password;
            },
          ),
        ),
      );
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.text('New password'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Create new password'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).first, 'new-password');
      await tester.enterText(find.byType(TextField).last, 'different-password');
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(submittedCode, isNull);
      await tester.enterText(find.byType(TextField).last, 'new-password');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '123456',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'new-password',
      );
      await tester.tap(find.text('Reset password'));
      expect(submittedCode, '123456');
      expect(submittedPassword, 'new-password');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'resend becomes available after cooldown and only resets on successful delivery',
    (tester) async {
      var requests = 0;
      var resending = false;
      String? error;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AppPasswordResetFlow(
                email: 'person@example.com',
                minimumPasswordLength: 8,
                onBack: () {},
                onSubmit: (_, _) {},
                onResend: () => requests++,
                isResending: resending,
                errorMessage: error,
              );
            },
          ),
        ),
      );
      expect(find.text('Resend in 1:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Resend code'));
      expect(requests, 1);
      await tester.enterText(find.byType(TextField), '123456');
      update(() => resending = true);
      await tester.pump();
      update(() {
        resending = false;
        error = 'Delivery failed.';
      });
      await tester.pump();
      expect(find.text('Delivery failed.'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '123456',
      );
      update(() {
        resending = true;
        error = null;
      });
      await tester.pump();
      update(() => resending = false);
      await tester.pump();
      expect(find.text('Resend in 1:00'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
