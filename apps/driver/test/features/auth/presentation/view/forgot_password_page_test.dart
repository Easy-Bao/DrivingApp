import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:driver/src/features/auth/presentation/view/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('shows a reset failure once in the page', (tester) async {
    final repository = _MockAuthRepository();
    when(() => repository.resetPassword(email: 'driver@example.com'))
        .thenAnswer((_) async => const Err(ServerFailure('request failed')));
    final bloc = ForgotPasswordBloc(repository);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: ForgotPasswordPage(forgotPasswordBloc: bloc),
      ),
    );
    await tester.enterText(find.byType(TextField), 'driver@example.com');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('validates inline and prevents repeat code requests', (
    tester,
  ) async {
    final repository = _MockAuthRepository();
    final pending = Completer<Result<void, Failure>>();
    when(() => repository.resetPassword(email: 'driver@example.com'))
        .thenAnswer((_) => pending.future);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: ForgotPasswordPage(
          forgotPasswordBloc: ForgotPasswordBloc(repository),
        ),
      ),
    );
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Back to sign in'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    verifyNever(() => repository.resetPassword(email: any(named: 'email')));
    await tester.enterText(find.byType(TextField), 'driver@example.com');
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsNothing);
    await tester.ensureVisible(find.text('Send code'));
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    tester.widget<TextField>(find.byType(TextField)).onSubmitted!(
      'driver@example.com',
    );
    await tester.pump();
    verify(() => repository.resetPassword(email: 'driver@example.com'))
        .called(1);
    pending.complete(const Err(ServerFailure('request failed')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('keeps send code reachable with large text and keyboard insets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _MockAuthRepository();
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
        home: ForgotPasswordPage(
          forgotPasswordBloc: ForgotPasswordBloc(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
