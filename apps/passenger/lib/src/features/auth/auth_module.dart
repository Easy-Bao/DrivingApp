import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/data/data_sources/passenger_auth_remote_data_source.dart';
import 'package:passenger/src/features/auth/data/repositories/passenger_auth_repository_impl.dart';
import 'package:passenger/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/reset_password_confirm/reset_password_confirm_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger/src/features/auth/presentation/view/forgot_password_page.dart';
import 'package:passenger/src/features/auth/presentation/view/reset_password_confirm_page.dart';
import 'package:passenger/src/features/auth/presentation/view/sign_in_page.dart';
import 'package:passenger/src/features/auth/presentation/view/sign_up_page.dart';
import 'package:passenger/src/features/auth/presentation/view/verify_otp_page.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: AuthRoutes.root,
      AuthRoutes.rootPath,
      child: (context, GoRouterState state) => const SizedBox.shrink(),
      guards: [GuardFn((_, state) => authRootRedirect(state.uri))],
    ),
    ChildRoute(
      name: AuthRoutes.signin,
      AuthRoutes.signinPath,
      child: (context, GoRouterState state) => const SigninPage(),
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.signup,
      AuthRoutes.signupPath,
      child: (context, GoRouterState state) => const SignupPage(),
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.forgotPassword,
      AuthRoutes.forgotPasswordPath,
      child: (context, GoRouterState state) => const ForgotPasswordPage(),
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.verifyOtp,
      AuthRoutes.verifyOtpPath,
      child: (context, GoRouterState state) {
        final extra = state.extra is Map ? state.extra as Map : {};
        final email =
            (state.uri.queryParameters['email'] ??
                extra['email']?.toString()) ??
            '';
        final isForgotPassword = extra['isForgotPassword'] == true;
        return VerifyOtpPage(email: email, isForgotPassword: isForgotPassword);
      },
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.resetPasswordConfirm,
      AuthRoutes.resetPasswordConfirmPath,
      child: (context, GoRouterState state) {
        final extra = state.extra is Map ? state.extra as Map : {};
        final email = extra['email']?.toString() ?? '';
        final code = extra['code']?.toString() ?? '';
        return ResetPasswordConfirmPage(email: email, code: code);
      },
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  @override
  void binds(Injector i) {
    i
      ..addLazySingleton<PassengerAuthRemoteDataSource>(
        (i) => PassengerAuthRemoteDataSourceImpl(i.get()),
      )
      ..addLazySingleton<PassengerAuthRepository>(
        (i) => PassengerAuthRepositoryImpl(
          remoteDataSource: i.get<PassengerAuthRemoteDataSource>(),
          secureSessionService: i.get<PassengerSessionStore>(),
          preferences: i.get<SharedPreferences>(),
        ),
      );
    i.add<SignInBloc>((i) => SignInBloc(i.get<PassengerAuthRepository>()));
    i.add<SignUpBloc>((i) => SignUpBloc(i.get<PassengerAuthRepository>()));
    i.add<VerifyOtpBloc>(
      (i) => VerifyOtpBloc(i.get<PassengerAuthRepository>()),
    );
    i.add<ForgotPasswordBloc>(
      (i) => ForgotPasswordBloc(i.get<PassengerAuthRepository>()),
    );
    i.add<ResetPasswordConfirmBloc>(
      (i) => ResetPasswordConfirmBloc(i.get<PassengerAuthRepository>()),
    );
  }
}
