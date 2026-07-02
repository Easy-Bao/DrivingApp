/// Authentication module: defines the routing paths for driver sign-in and password recovery.
library;

import 'package:driver_app/features/auth/presentation/views/forgot_password_screen.dart';
import 'package:driver_app/features/auth/presentation/views/signin_screen.dart';
import 'package:driver_app/core/transitions/app_transitions.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: 'Signin',
      '/',
      child: (context, GoRouterState state) => const SigninScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
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
