import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';
import 'package:driver/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:driver/src/features/auth/presentation/view/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  testWidgets(
    'validates input, clears errors on changed, and displays failure in banner',
    (tester) async {
      when(
        () => repository.authenticate(
          email: 'driver@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const Err(InvalidCredentialsFailure()));

      final bloc = SignInBloc(repository);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: SigninPage(signInBloc: bloc),
        ),
      );

      expect(find.text('Remember me'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.pump();
      expect(find.text('Enter your email address.'), findsNothing);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).first,
        'driver@example.com',
      );
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(find.text('Enter your password.'), findsNothing);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorBanner), findsOneWidget);
      expect(find.text('Incorrect email or password.'), findsOneWidget);

      await bloc.close();
    },
  );
  testWidgets('keeps labels, autofill, and password visibility accessible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: SigninPage(signInBloc: SignInBloc(repository)),
      ),
    );
    expect(find.byType(AppAuthBrand), findsNothing);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.textContaining('By signing in'), findsOneWidget);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.first.autofillHints, contains(AutofillHints.username));
    expect(fields.last.autofillHints, contains(AutofillHints.password));
    expect(fields.last.obscureText, isTrue);
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'secret',
    );
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('prevents repeated submission while signing in', (tester) async {
    final pending = Completer<Result<AuthCredentials, Failure>>();
    when(
      () => repository.authenticate(
        email: 'driver@example.com',
        password: 'password123',
      ),
    ).thenAnswer((_) => pending.future);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: SigninPage(signInBloc: SignInBloc(repository)),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'driver@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isFalse,
    );
    tester.widget<TextField>(find.byType(TextField).last).onSubmitted!(
      'password123',
    );
    await tester.pump();
    verify(
      () => repository.authenticate(
        email: 'driver@example.com',
        password: 'password123',
      ),
    ).called(1);
    pending.complete(const Err(InvalidCredentialsFailure()));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('scrolls the form with large text and the keyboard open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
        home: SigninPage(signInBloc: SignInBloc(repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
