import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:passenger/src/features/auth/presentation/pages/sign_in_page.dart';

class _AuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('Remember me toggles through both its label and checkbox', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: SigninPage(signInBloc: SignInBloc(_AuthRepository())),
      ),
    );
    await tester.ensureVisible(find.text('Remember me'));
    expect(
      (tester.getCenter(find.text('Remember me')).dy -
              tester.getCenter(find.text('Forgot password?')).dy)
          .abs(),
      lessThan(2),
    );
    final button = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Remember me'),
        matching: find.byType(TextButton),
      ),
    );
    expect(
      button.style!.overlayColor!.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.text('Remember me'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tapAt(tester.getCenter(find.byType(Checkbox)));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  for (final rememberMe in [true, false]) {
    testWidgets(
      'submits rememberMe=$rememberMe and disables changes while signing in',
      (tester) async {
        final repository = _AuthRepository();
        final response = Completer<Result<AuthCredentials, Failure>>();
        when(
          () => repository.authenticate(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberMe: any(named: 'rememberMe'),
          ),
        ).thenAnswer((_) => response.future);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.main,
            home: SigninPage(signInBloc: SignInBloc(repository)),
          ),
        );
        await tester.enterText(
          find.byType(TextField).at(0),
          'passenger@example.com',
        );
        await tester.enterText(find.byType(TextField).at(1), 'test-password');
        await tester.ensureVisible(find.text('Remember me'));
        if (rememberMe) {
          await tester.tap(find.text('Remember me'));
          await tester.pump();
        }
        await tester.ensureVisible(find.text('Sign In'));
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        final tile = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(tile.value, rememberMe);
        expect(tile.onChanged, isNull);
        verify(
          () => repository.authenticate(
            email: 'passenger@example.com',
            password: 'test-password',
            rememberMe: rememberMe,
          ),
        ).called(1);
        response.complete(const Err(ServerFailure('Sign in failed.')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox)).onChanged,
          isNotNull,
        );
      },
    );
  }
}
