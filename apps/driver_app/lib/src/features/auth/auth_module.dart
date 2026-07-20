import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_app/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_app/src/features/auth/domain/usecases/authenticate_use_case.dart';
import 'package:driver_app/src/features/auth/presentation/cubits/signin_cubit.dart';
import 'package:driver_app/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:driver_app/src/features/auth/presentation/screens/signin_screen.dart';
import 'package:driver_services/driver_services.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/transitions/driver_transitions.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthRemoteDataSource>(
      (i) => AuthRemoteDataSourceImpl(i.get<AuthApiService>()),
    );
    i.addLazySingleton<AuthRepository>(
      (i) => AuthRepositoryImpl(
        remoteDataSource: i.get<AuthRemoteDataSource>(),
        secureSessionService: i.get<SecureSessionService>(),
      ),
    );
    i.addLazySingleton<AuthenticateUseCase>(
      (i) => AuthenticateUseCase(i.get<AuthRepository>()),
    );
    i.add<SignInCubit>(
      (i) => SignInCubit(i.get<AuthenticateUseCase>()),
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
