import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/reset_password_confirm/reset_password_confirm_bloc.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger_app/src/features/auth/data/repositories/passenger_auth_repository.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:passenger_app/src/features/auth/domain/use_cases/confirm_reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/use_cases/register_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/use_cases/resend_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/use_cases/reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/use_cases/verify_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/forgot_password_page.dart';
import 'package:passenger_app/src/features/auth/presentation/reset_password_confirm_page.dart';
import 'package:passenger_app/src/features/auth/presentation/sign_in_page.dart';
import 'package:passenger_app/src/features/auth/presentation/sign_up_page.dart';
import 'package:passenger_app/src/features/auth/presentation/verify_otp_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:design_system/design_system.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<PassengerAuthRepository>(
      (i) => PassengerAuthRepositoryImpl(
        remoteDataSource: i.get<AuthRemoteDataSource>(),
        secureSessionService: i.get<SecureSessionService>(),
        preferences: i.get<SharedPreferences>(),
      ),
    );
    i.addLazySingleton<SignInUseCase>(
      (i) => SignInUseCase(i.get<PassengerAuthRepository>()),
    );
    i.addLazySingleton<RegisterUseCase>(
      (i) => RegisterUseCase(i.get<PassengerAuthRepository>()),
    );
    i.addLazySingleton<VerifyOtpUseCase>(
      (i) => VerifyOtpUseCase(i.get<PassengerAuthRepository>()),
    );
    i.addLazySingleton<ResendOtpUseCase>(
      (i) => ResendOtpUseCase(i.get<PassengerAuthRepository>()),
    );
    i.addLazySingleton<ResetPasswordUseCase>(
      (i) => ResetPasswordUseCase(i.get<PassengerAuthRepository>()),
    );
    i.addLazySingleton<ConfirmResetPasswordUseCase>(
      (i) => ConfirmResetPasswordUseCase(i.get<PassengerAuthRepository>()),
    );
    i.add<SignInBloc>((i) => SignInBloc(i.get<SignInUseCase>()));
    i.add<SignUpBloc>((i) => SignUpBloc(i.get<RegisterUseCase>()));
    i.add<VerifyOtpBloc>(
      (i) =>
          VerifyOtpBloc(i.get<VerifyOtpUseCase>(), i.get<ResendOtpUseCase>()),
    );
    i.add<ForgotPasswordBloc>(
      (i) => ForgotPasswordBloc(i.get<ResetPasswordUseCase>()),
    );
    i.add<ResetPasswordConfirmBloc>(
      (i) => ResetPasswordConfirmBloc(i.get<ConfirmResetPasswordUseCase>()),
    );
  }

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
}
