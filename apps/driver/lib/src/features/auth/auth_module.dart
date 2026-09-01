import 'package:dio/dio.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/auth/data/data_sources/driver_auth_remote_data_source.dart';
import 'package:driver/src/features/auth/data/repositories/driver_auth_repository_impl.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:driver/src/features/auth/presentation/view/forgot_password_page.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:driver/src/features/auth/presentation/view/sign_in_page.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i
      ..addLazySingleton<DriverAuthRemoteDataSource>(
        (i) => DriverAuthRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DriverAuthRepository>(
        (i) => DriverAuthRepositoryImpl(
          remoteDataSource: i.get<DriverAuthRemoteDataSource>(),
          secureSessionService: i.get<DriverSessionStore>(),
        ),
      );
    i.add<SignInBloc>((i) => SignInBloc(i.get<DriverAuthRepository>()));
    i.add<ForgotPasswordBloc>(
      (i) => ForgotPasswordBloc(i.get<DriverAuthRepository>()),
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
