import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:driver/src/features/auth/presentation/view/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverAuthRepository extends Mock implements DriverAuthRepository {}

void main() {
  late _MockDriverAuthRepository repository;

  setUp(() {
    repository = _MockDriverAuthRepository();
  });

  testWidgets(
    'validates input, clears errors on changed, and displays failure in banner',
    (tester) async {
      when(
        () => repository.authenticate(
          email: 'driver@example.com',
          password: 'password123',
        ),
      ).thenAnswer(
        (_) async => const Err(InvalidCredentialsFailure()),
      );

      final bloc = SignInBloc(repository);
      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
          home: SigninPage(signInBloc: bloc),
        ),
      );

      // Verify no remember me checkbox exists
      expect(find.text('Remember me'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);

      // Attempt submit with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);

      // Typing in email clears email error
      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.pump();
      expect(find.text('Enter your email address.'), findsNothing);

      // Submit with invalid email format
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address.'), findsOneWidget);

      // Enter valid email and password
      await tester.enterText(
        find.byType(TextField).first,
        'driver@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(find.text('Enter your password.'), findsNothing);

      // Submit valid credentials that fail on server
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // AppErrorBanner displays server error, not inline password errorText
      expect(find.byType(AppErrorBanner), findsOneWidget);
      expect(find.text('Incorrect email or password.'), findsOneWidget);

      await bloc.close();
    },
  );
}
