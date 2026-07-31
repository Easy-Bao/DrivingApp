import 'package:driver_app/src/Features/Auth/AuthRoutes.dart';
import 'package:driver_app/src/Features/Auth/Data/DataSources/AuthRemoteDataSource.dart';
import 'package:driver_app/src/Features/Auth/Data/Repositories/AuthRepositoryImpl.dart';
import 'package:driver_app/src/Features/Auth/Domain/Repositories/AuthRepository.dart';
import 'package:driver_app/src/Features/Auth/Domain/Usecases/ResetPasswordUseCase.dart';
import 'package:driver_app/src/Features/Auth/Domain/Usecases/SignInUseCase.dart';
import 'package:driver_app/src/Features/Auth/Presentation/ForgotPassword/Bloc/ForgotPasswordBloc.dart';
import 'package:driver_app/src/Features/Auth/Presentation/ForgotPassword/Screens/ForgotPasswordScreen.dart';
import 'package:driver_app/src/Features/Auth/Presentation/Signin/Bloc/SignInBloc.dart';
import 'package:driver_app/src/Features/Auth/Presentation/Signin/Screens/SignInScreen.dart';
 as ps;
import 'package:go_router_modular/go_router_modular.dart';

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
