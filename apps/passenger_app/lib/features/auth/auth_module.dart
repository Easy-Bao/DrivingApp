import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/core/transitions/app_transitions.dart';
import 'package:passenger_app/features/auth/presentation/views/forgot_password_screen.dart';
import 'package:passenger_app/features/auth/presentation/views/onboarding_screen.dart';
import 'package:passenger_app/features/auth/presentation/views/signin_screen.dart';
import 'package:passenger_app/features/auth/presentation/views/signup_screen.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: 'OnBoarding',
      '/',
      child: (context, GoRouterState state) => const OnBoardingScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: 'Signin',
      '/auth/signin',
      child: (context, GoRouterState state) => const SigninScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'Signup',
      '/auth/signup',
      child: (context, GoRouterState state) => const SignupScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'ForgotPassword',
      '/auth/forgotpassword',
      child: (context, GoRouterState state) => const ForgotPasswordScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}
