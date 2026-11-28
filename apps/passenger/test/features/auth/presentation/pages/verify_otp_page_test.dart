import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger/src/features/auth/domain/entities/session.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger/src/features/auth/presentation/pages/verify_otp_page.dart';
import 'package:passenger/src/features/home/home_routes.dart';

class _AuthRepository extends Mock implements AuthRepository {}

class _SessionRepository extends Mock implements SessionRepository {}

void main() {
  testWidgets(
    'shows confirmation snackbars when resending code and verifying email',
    (tester) async {
      final authRepository = _AuthRepository();
      final sessionRepository = _SessionRepository();
      when(
        () => authRepository.requestVerificationCode(
          email: 'passenger@example.com',
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => authRepository.verifyOtp(
          email: 'passenger@example.com',
          code: '123456',
        ),
      ).thenAnswer(
        (_) async => const Ok(
          AuthCredentials(
            passengerId: '42',
            passengerName: 'Test Passenger',
            passengerEmail: 'passenger@example.com',
            passengerPhone: '+639171234567',
            token: 'token',
          ),
        ),
      );
      when(() => sessionRepository.restoreSession()).thenAnswer(
        (_) async => const Ok(
          Session.authenticated(
            passengerId: '42',
            passengerName: 'Test Passenger',
          ),
        ),
      );

      final sessionBloc = SessionBloc(sessionRepository: sessionRepository);
      addTearDown(sessionBloc.close);

      final router = GoRouter(
        initialLocation: '/verify',
        routes: [
          GoRoute(
            path: '/verify',
            builder: (_, _) => VerifyOtpPage(
              email: 'passenger@example.com',
              verifyOtpBloc: VerifyOtpBloc(authRepository),
            ),
          ),
          GoRoute(
            path: '/home',
            name: HomeRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('Passenger Home')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        BlocProvider<SessionBloc>.value(
          value: sessionBloc,
          child: MaterialApp.router(theme: AppTheme.main, routerConfig: router),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 60));
      await tester.pump();

      await tester.tap(find.text('Resend code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Verification code sent.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();

      expect(find.text('Passenger Home'), findsOneWidget);
      expect(find.text('Email verified.'), findsOneWidget);
    },
  );
}
