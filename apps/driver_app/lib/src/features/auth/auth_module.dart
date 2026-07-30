import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_app/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_app/src/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:driver_app/src/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:driver_app/src/features/auth/presentation/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:driver_app/src/features/auth/presentation/forgot_password/screens/forgot_password_screen.dart';
import 'package:driver_app/src/features/auth/presentation/signin/bloc/sign_in_bloc.dart';
import 'package:driver_app/src/features/auth/presentation/signin/screens/sign_in_screen.dart';
import 'package:driver_services/driver_services.dart' as ps;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/shared_ui.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthRemoteDataSource>(
      (i) => AuthRemoteDataSourceImpl(i.get<ps.AuthRemoteDataSource>()),
    );
    i.addLazySingleton<AuthRepository>(
      (i) => AuthRepositoryImpl(
        remoteDataSource: i.get<AuthRemoteDataSource>(),
        secureSessionService: i.get<SecureSessionService>(),
      ),
    );
    i.addLazySingleton<SignInUseCase>(
      (i) => SignInUseCase(i.get<AuthRepository>()),
    );
    i.addLazySingleton<ResetPasswordUseCase>(
      (i) => ResetPasswordUseCase(i.get<AuthRepository>()),
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
