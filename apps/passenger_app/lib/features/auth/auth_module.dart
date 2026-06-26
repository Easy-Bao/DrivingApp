import 'package:passenger_app/features/auth/presentation/views/forgot_password_screen.dart';
import 'package:passenger_app/features/auth/presentation/views/onboarding_screen.dart';
import 'package:passenger_app/features/auth/presentation/views/signin_screen.dart';
import 'package:passenger_app/features/auth/presentation/views/signup_screen.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: 'OnBoarding',
      '/',
      child: (context, GoRouterState state) => const OnBoardingScreen(),
    ),
    ChildRoute(
      name: 'Signin',
      '/auth/signin',
      child: (context, GoRouterState state) => const SigninScreen(),
    ),
    ChildRoute(
      name: 'Signup',
      '/auth/signup',
      child: (context, GoRouterState state) => const SignupScreen(),
    ),
    ChildRoute(
      name: 'ForgotPassword',
      '/auth/forgotpassword',
      child: (context, GoRouterState state) => const ForgotPasswordScreen(),
    ),
  ];
}
