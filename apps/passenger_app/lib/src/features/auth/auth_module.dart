import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:passenger_app/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/authenticate_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/register_use_case.dart';
import 'package:passenger_app/src/features/auth/domain/usecases/verify_otp_use_case.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signin_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signup_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/signin_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:passenger_app/src/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthRemoteDataSource>(
      (i) => AuthRemoteDataSourceImpl(i.get<PassengerApiService>()),
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
    i.addLazySingleton<RegisterUseCase>(
      (i) => RegisterUseCase(i.get<AuthRepository>()),
    );
    i.addLazySingleton<VerifyOtpUseCase>(
      (i) => VerifyOtpUseCase(i.get<AuthRepository>()),
    );
    i.add<SignInCubit>(
      (i) => SignInCubit(i.get<AuthenticateUseCase>()),
    );
    i.add<SignUpCubit>(
      (i) => SignUpCubit(
        registerUseCase: i.get<RegisterUseCase>(),
        verifyOtpUseCase: i.get<VerifyOtpUseCase>(),
      ),
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
            final email = state.uri.queryParameters['email'] ?? '';
            return VerifyOtpScreen(email: email);
          },
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
      ];
}
