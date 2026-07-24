import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:passenger_app/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/confirm_reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/register_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/verify_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/forgot_password_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/reset_password_confirm_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signin_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signup_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/verify_otp_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/reset_password_confirm_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/signin_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:passenger_services/passenger_services.dart' as ps;
import 'package:session_service/session_service.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

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
    i.addLazySingleton<RegisterUseCase>(
      (i) => RegisterUseCase(i.get<AuthRepository>()),
    );
    i.addLazySingleton<VerifyOtpUseCase>(
      (i) => VerifyOtpUseCase(i.get<AuthRepository>()),
    );
    i.addLazySingleton<ResetPasswordUseCase>(
      (i) => ResetPasswordUseCase(i.get<AuthRepository>()),
    );
    i.addLazySingleton<ConfirmResetPasswordUseCase>(
      (i) => ConfirmResetPasswordUseCase(i.get<AuthRepository>()),
    );
    i.add<SignInCubit>(
      (i) => SignInCubit(i.get<SignInUseCase>()),
    );
    i.add<SignUpCubit>(
      (i) => SignUpCubit(
        registerUseCase: i.get<RegisterUseCase>(),
        verifyOtpUseCase: i.get<VerifyOtpUseCase>(),
      ),
    );
    i.add<VerifyOtpCubit>(
      (i) => VerifyOtpCubit(i.get<VerifyOtpUseCase>()),
    );
    i.add<ForgotPasswordCubit>(
      (i) => ForgotPasswordCubit(i.get<ResetPasswordUseCase>()),
    );
    i.add<ResetPasswordConfirmCubit>(
      (i) => ResetPasswordConfirmCubit(i.get<ConfirmResetPasswordUseCase>()),
    );
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          name: AuthRoutes.onBoarding,
          '/',
          child: (context, GoRouterState state) => const OnBoardingScreen(),
          transition: AppTransitions.fade,
          transitionDuration: AppTransitions.fadeDuration,
        ),
        ChildRoute(
          name: AuthRoutes.signin,
          '/auth/signin',
          child: (context, GoRouterState state) => const SigninScreen(),
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
        ChildRoute(
          name: AuthRoutes.signup,
          '/auth/signup',
          child: (context, GoRouterState state) => const SignupScreen(),
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
        ChildRoute(
          name: AuthRoutes.forgotPassword,
          '/auth/forgotpassword',
          child: (context, GoRouterState state) => const ForgotPasswordScreen(),
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
        ChildRoute(
          name: AuthRoutes.verifyOtp,
          '/auth/verifyotp',
          child: (context, GoRouterState state) {
            final extra = state.extra is Map ? state.extra as Map : {};
            final email =
                (state.uri.queryParameters['email'] ?? extra['email']?.toString()) ?? '';
            final password = extra['password']?.toString() ?? '';
            final isForgotPassword = extra['isForgotPassword'] == true;
            return VerifyOtpScreen(
              email: email,
              password: password,
              isForgotPassword: isForgotPassword,
            );
          },
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
        ChildRoute(
          name: AuthRoutes.resetPasswordConfirm,
          '/auth/resetpassword',
          child: (context, GoRouterState state) {
            final extra = state.extra is Map ? state.extra as Map : {};
            final email = extra['email']?.toString() ?? '';
            final code = extra['code']?.toString() ?? '';
            return ResetPasswordConfirmScreen(email: email, otpCode: code);
          },
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
      ];
}
