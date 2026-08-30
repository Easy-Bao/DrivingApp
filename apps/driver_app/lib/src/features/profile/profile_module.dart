import 'dart:async';

import 'package:dio/dio.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/bloc/performance/driver_performance_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:driver_app/src/features/profile/data/repositories/driver_profile_repository.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/profile/view/driver_account_page.dart';
import 'package:driver_app/src/features/profile/view/driver_performance_page.dart';
import 'package:driver_app/src/features/profile/view/driver_personal_details_page.dart';
import 'package:driver_app/src/features/profile/view/driver_vehicle_information_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class ProfileModule {
  ProfileModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverProfileRemoteDataSource>(
        (i) => DriverProfileRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<IDriverProfileRepository>(
        (i) => DriverProfileRepository(
          profileDataSource: i.get<DriverProfileRemoteDataSource>(),
          sessionService: i.get<SecureSessionService>(),
          preferences: i.get<SharedPreferences>(),
        ),
      )
      ..addFactory<DriverAccountCubit>(
        (i) =>
            DriverAccountCubit(repository: i.get<IDriverProfileRepository>()),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ProfileRoutes.personalDetails,
      ProfileRoutes.personalDetailsPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<DriverAccountCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const DriverPersonalDetailsPage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ProfileRoutes.vehicleInformation,
      ProfileRoutes.vehicleInformationPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<DriverAccountCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const DriverVehicleInformationPage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ProfileRoutes.performance,
      ProfileRoutes.performancePath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<DriverPerformanceCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const DriverPerformancePage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> accountShellRoutes = [
    ChildRoute(
      name: ProfileRoutes.account,
      ProfileRoutes.accountPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<DriverAccountCubit>();
          cubit.load();
          return cubit;
        },
        child: const DriverAccountPage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
