import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver_app/src/features/auth/domain/use_cases/reset_password_use_case.dart';
import 'package:driver_app/src/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:driver_app/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:driver_app/src/features/auth/presentation/forgot_password_page.dart';
import 'package:driver_app/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:driver_app/src/features/auth/presentation/sign_in_page.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<SignInUseCase>(
      (i) => SignInUseCase(i.get<DriverAuthRepository>()),
    );
    i.addLazySingleton<ResetPasswordUseCase>(
      (i) => ResetPasswordUseCase(i.get<DriverAuthRepository>()),
    );
    i.add<SignInBloc>((i) => SignInBloc(i.get<SignInUseCase>()));
    i.add<ForgotPasswordBloc>(
      (i) => ForgotPasswordBloc(i.get<ResetPasswordUseCase>()),
    );
  }

  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: AuthRoutes.signin,
      AuthRoutes.signinPath,
      child: (context, GoRouterState state) => const SigninPage(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: AuthRoutes.forgotPassword,
      AuthRoutes.forgotPasswordPath,
      child: (context, GoRouterState state) => const ForgotPasswordPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}
