import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:passenger_app/src/features/auth/bloc/reset_password_confirm/reset_password_confirm_bloc.dart';
import 'package:passenger_app/src/features/auth/bloc/sign_in/sign_in_bloc.dart';
import 'package:passenger_app/src/features/auth/bloc/sign_up/sign_up_bloc.dart';
import 'package:passenger_app/src/features/auth/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:passenger_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/confirm_reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/register_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/resend_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/verify_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/view/forgot_password_screen.dart';
import 'package:passenger_app/src/features/auth/view/onboarding_screen.dart';
import 'package:passenger_app/src/features/auth/view/reset_password_confirm_screen.dart';
import 'package:passenger_app/src/features/auth/view/sign_in_screen.dart';
import 'package:passenger_app/src/features/auth/view/sign_up_screen.dart';
import 'package:passenger_app/src/features/auth/view/verify_otp_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<IAuthRepository>(
      (i) => AuthRepository(
        remoteDataSource: i.get<AuthRemoteDataSource>(),
        secureSessionService: i.get<SecureSessionService>(),
        preferences: i.get<SharedPreferences>(),
      ),
    );
    i.addLazySingleton<SignInUseCase>(
      (i) => SignInUseCase(i.get<IAuthRepository>()),
    );
    i.addLazySingleton<RegisterUseCase>(
      (i) => RegisterUseCase(i.get<IAuthRepository>()),
    );
    i.addLazySingleton<VerifyOtpUseCase>(
      (i) => VerifyOtpUseCase(i.get<IAuthRepository>()),
    );
    i.addLazySingleton<ResendOtpUseCase>(
      (i) => ResendOtpUseCase(i.get<IAuthRepository>()),
    );
    i.addLazySingleton<ResetPasswordUseCase>(
      (i) => ResetPasswordUseCase(i.get<IAuthRepository>()),
    );
    i.addLazySingleton<ConfirmResetPasswordUseCase>(
      (i) => ConfirmResetPasswordUseCase(i.get<IAuthRepository>()),
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
      name: AuthRoutes.onBoarding,
      '/',
      child: (context, GoRouterState state) => const OnBoardingScreen(),
      transition: AppTransitions.fadeThrough,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: AuthRoutes.signin,
      '/auth/signin',
      child: (context, GoRouterState state) => const SigninScreen(),
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.signup,
      '/auth/signup',
      child: (context, GoRouterState state) => const SignupScreen(),
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.forgotPassword,
      '/auth/forgotpassword',
      child: (context, GoRouterState state) => const ForgotPasswordScreen(),
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.verifyOtp,
      '/auth/verifyotp',
      child: (context, GoRouterState state) {
        final extra = state.extra is Map ? state.extra as Map : {};
        final email =
            (state.uri.queryParameters['email'] ??
                extra['email']?.toString()) ??
            '';
        final isForgotPassword = extra['isForgotPassword'] == true;
        return VerifyOtpScreen(
          email: email,
          isForgotPassword: isForgotPassword,
        );
      },
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: AuthRoutes.resetPasswordConfirm,
      '/auth/resetpassword',
      child: (context, GoRouterState state) {
        final extra = state.extra is Map ? state.extra as Map : {};
        final email = extra['email']?.toString() ?? '';
        final code = extra['code']?.toString() ?? '';
        return ResetPasswordConfirmScreen(email: email, code: code);
      },
      transition: AppTransitions.sharedAxisHorizontal,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}
