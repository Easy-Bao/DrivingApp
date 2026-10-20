import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/auth/data/repositories/driver_auth_repository_impl.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:driver/src/features/auth/presentation/view/forgot_password_page.dart';
import 'package:driver/src/features/auth/presentation/view/sign_in_page.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => AuthRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<AuthRepository>(
        (i) => AuthRepositoryImpl(
          remoteDataSource: i.get<AuthRemoteDataSource>(),
          secureSessionService: i.get<SessionStore>(),
        ),
      );
    i.add<SignInBloc>((i) => SignInBloc(i.get<AuthRepository>()));
    i.add<ForgotPasswordBloc>(
      (i) => ForgotPasswordBloc(i.get<AuthRepository>()),
    );
  }

  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: AuthRoutes.signin,
      AuthRoutes.signinPath,
      child: (context, GoRouterState state) =>
          SigninPage(signInBloc: Modular.get<SignInBloc>()),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: AuthRoutes.forgotPassword,
      AuthRoutes.forgotPasswordPath,
      child: (context, GoRouterState state) => ForgotPasswordPage(
        forgotPasswordBloc: Modular.get<ForgotPasswordBloc>(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}
