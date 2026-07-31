import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Auth/AuthRoutes.dart';
import 'package:passenger_app/src/Features/Auth/Data/DataSources/AuthRemoteDataSource.dart';
import 'package:passenger_app/src/Features/Auth/Data/Repositories/AuthRepositoryImpl.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Repositories/AuthRepository.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/ConfirmResetPasswordUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/RegisterUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/ResetPasswordUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/SignInUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Usecases/VerifyOtpUseCase.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ForgotPassword/Bloc/ForgotPasswordBloc.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ForgotPassword/Screens/ForgotPasswordScreen.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ResetPasswordConfirm/Bloc/ResetPasswordConfirmBloc.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ResetPasswordConfirm/Screens/ResetPasswordConfirmScreen.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Screens/OnboardingScreen.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signin/Bloc/SignInBloc.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signin/Screens/SignInScreen.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signup/Bloc/SignUpBloc.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signup/Screens/SignUpScreen.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Verify_otp/Bloc/VerifyOtpBloc.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Verify_otp/Screens/VerifyOtpScreen.dart';
 as ps;

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
    i.add<SignInBloc>(
      (i) => SignInBloc(i.get<SignInUseCase>()),
    );
    i.add<SignUpBloc>(
      (i) => SignUpBloc(i.get<RegisterUseCase>()),
    );
    i.add<VerifyOtpBloc>(
      (i) => VerifyOtpBloc(i.get<VerifyOtpUseCase>()),
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
                (state.uri.queryParameters['email'] ?? extra['email']?.toString()) ?? '';
            final password = extra['password']?.toString() ?? '';
            final isForgotPassword = extra['isForgotPassword'] == true;
            return VerifyOtpScreen(
              email: email,
              password: password,
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
