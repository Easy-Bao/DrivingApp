import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';
import 'package:driver/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_bloc.dart';
import 'package:driver/src/features/auth/presentation/pages/reset_password_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets(
    'shows password guidance, visibility, and a single code failure',
    (tester) async {
      final repository = _MockAuthRepository();
      when(
        () => repository.verifyResetOtp(
          email: 'driver@example.com',
          code: '000000',
        ),
      ).thenAnswer((_) async => const Err(InvalidVerificationCodeFailure()));
      when(
        () => repository.verifyResetOtp(
          email: 'driver@example.com',
          code: '123456',
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repository.confirmPasswordReset(
          email: 'driver@example.com',
          code: '123456',
          newPassword: 'new-password',
        ),
      ).thenAnswer((_) async => const Err(ServerFailure('rejected code')));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: ResetPasswordPage(
            email: 'driver@example.com',
            resetPasswordBloc: ResetPasswordBloc(repository),
          ),
        ),
      );
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.text('New password'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).autofillHints,
        contains(AutofillHints.oneTimeCode),
      );
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.text('Create new password'), findsNothing);
      expect(
        find.text('That verification code is invalid or expired. Try again.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Create new password'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'new-password');
      await tester.enterText(find.byType(TextField).last, 'new-password');
      await tester.pump();
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).obscureText,
        isFalse,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();
      verify(
        () => repository.confirmPasswordReset(
          email: 'driver@example.com',
          code: '123456',
          newPassword: 'new-password',
        ),
      ).called(1);
      expect(
        find.text('The server could not complete your request. Try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps reset reachable with large text and keyboard insets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _MockAuthRepository();
    when(
      () => repository.verifyResetOtp(
        email: 'driver@example.com',
        code: '123456',
      ),
    ).thenAnswer((_) async => const Ok(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            viewInsets: const EdgeInsets.only(bottom: 240),
          ),
          child: child!,
        ),
        home: ResetPasswordPage(
          email: 'driver@example.com',
          resetPasswordBloc: ResetPasswordBloc(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Reset password'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
