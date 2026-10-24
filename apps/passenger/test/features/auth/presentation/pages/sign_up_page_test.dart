import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart';
import 'package:passenger/src/features/auth/presentation/pages/sign_up_page.dart';

class _AuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets(
    'validates registration fields and preserves password visibility',
    (tester) async {
      final repository = _AuthRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: SignupPage(signUpBloc: SignUpBloc(repository)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your full name.'), findsOneWidget);
      expect(find.text('Enter your phone number.'), findsOneWidget);
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      verifyNever(
        () => repository.registerPassenger(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        ),
      );
      await tester.enterText(find.byType(TextField).last, 'new-password');
      await tester.ensureVisible(find.byTooltip('Show password'));
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).autofillHints,
        contains(AutofillHints.newPassword),
      );
      expect(find.byType(AppAuthBrand), findsNothing);
    },
  );

  testWidgets(
    'normalizes mobile number and continues to email verification once',
    (tester) async {
      final repository = _AuthRepository();
      final response = Completer<Result<Map<String, dynamic>, Failure>>();
      when(
        () => repository.registerPassenger(
          name: 'Test Passenger',
          email: 'passenger@example.com',
          phone: '+639171234567',
          password: 'new-password',
        ),
      ).thenAnswer((_) => response.future);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => SignupPage(signUpBloc: SignUpBloc(repository)),
          ),
          GoRoute(
            path: '/verify',
            name: AuthRoutes.verifyOtp,
            builder: (_, state) => Scaffold(
              body: Text('Verify ${(state.extra! as Map)['email']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Test Passenger');
      await tester.enterText(find.byType(TextField).at(1), '09171234567');
      await tester.enterText(
        find.byType(TextField).at(2),
        'passenger@example.com',
      );
      await tester.enterText(find.byType(TextField).at(3), 'new-password');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.enabled == false),
        isTrue,
      );
      tester.widget<TextField>(find.byType(TextField).last).onSubmitted!(
        'new-password',
      );
      await tester.pump();
      verify(
        () => repository.registerPassenger(
          name: 'Test Passenger',
          email: 'passenger@example.com',
          phone: '+639171234567',
          password: 'new-password',
        ),
      ).called(1);
      response.complete(const Ok({'needsVerification': true}));
      await tester.pumpAndSettle();
      expect(find.text('Verify passenger@example.com'), findsOneWidget);
    },
  );

  testWidgets('keeps sign-up usable with large text and keyboard insets', (
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
        home: SignupPage(signUpBloc: SignUpBloc(_AuthRepository())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
