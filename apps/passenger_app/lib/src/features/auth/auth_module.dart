import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/signin_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: AuthRoutes.onBoarding,
      '/',
      child: (context, GoRouterState state) => const OnBoardingScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: AuthRoutes.signin,
      '/auth/signin',
      child: (context, GoRouterState state) => const SigninScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.signup,
      '/auth/signup',
      child: (context, GoRouterState state) => const SignupScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.forgotPassword,
      '/auth/forgotpassword',
      child: (context, GoRouterState state) => const ForgotPasswordScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.verifyOtp,
      '/auth/verifyotp',
      child: (context, GoRouterState state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return VerifyOtpScreen(email: email);
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}
