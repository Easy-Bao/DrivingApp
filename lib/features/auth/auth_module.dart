import 'package:BaoRide/features/auth/presentation/views/forgot_password_screen.dart';
import 'package:BaoRide/features/auth/presentation/views/signin_screen.dart';
import 'package:BaoRide/features/auth/presentation/views/onboarding_screen.dart';
import 'package:BaoRide/features/auth/presentation/views/signup_screen.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: "OnBoarding",
      '/',
      child: (context, GoRouterState state) => const OnBoardingScreen(),
    ),
    ChildRoute(
      name: "Signin",
      '/auth/signin',
      child: (context, GoRouterState state) => const SigninScreen(),
      transition: GoTransitions.slide.toLeft.withFade,
    ),
    ChildRoute(
      name: "Signup",
      "/auth/signup",
      child: (context, GoRouterState state) => const SignupScreen(),
      transition: GoTransitions.slide.toLeft.withFade,
    ),
    ChildRoute(
      name: "ForgotPassword",
      "/auth/forgotpassword",
      child: (context, GoRouterState state) => const ForgotPasswordScreen(),
      transition: GoTransitions.slide.toLeft.withFade,
    ),
  ];
}
