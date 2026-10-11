import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:driver/src/features/auth/presentation/view/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverAuthRepository extends Mock implements DriverAuthRepository {}

void main() {
  testWidgets('shows a reset failure once in the page', (tester) async {
    final repository = _MockDriverAuthRepository();
    when(() => repository.resetPassword(email: 'driver@example.com'))
        .thenAnswer((_) async => const Err(ServerFailure('request failed')));
    final bloc = ForgotPasswordBloc(repository);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: ForgotPasswordPage(forgotPasswordBloc: bloc),
      ),
    );
    await tester.enterText(find.byType(TextField), 'driver@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
