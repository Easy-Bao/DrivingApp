import 'package:shared_ui/transitions/driver_transitions.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/auth/presentation/views/forgot_password_screen.dart';
import 'package:driver_app/src/features/auth/presentation/views/signin_screen.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: AuthRoutes.signin,
      '/',
      child: (context, GoRouterState state) => const SigninScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: AuthRoutes.forgotPassword,
      '/auth/forgotpassword',
      child: (context, GoRouterState state) => const ForgotPasswordScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}
