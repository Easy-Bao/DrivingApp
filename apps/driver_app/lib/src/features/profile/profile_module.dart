import 'package:dio/dio.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/view/earnings_page.dart';
import 'package:driver_app/src/features/profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:driver_app/src/features/profile/data/repositories/driver_profile_repository.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/profile/view/driver_account_page.dart';
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
          activityRepository: i.get<IDriverActivityRepository>(),
          sessionService: i.get<SecureSessionService>(),
          preferences: i.get<SharedPreferences>(),
        ),
      );
  }

  static List<ModularRoute> routes = [];

  static List<ModularRoute> earningsShellRoutes = [
    ChildRoute(
      name: ProfileRoutes.earnings,
      ProfileRoutes.earningsPath,
      child: (context, GoRouterState state) => const DriverEarningsPage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];

  static List<ModularRoute> accountShellRoutes = [
    ChildRoute(
      name: ProfileRoutes.account,
      ProfileRoutes.accountPath,
      child: (context, GoRouterState state) => DriverAccountPage(
        repository: Modular.get<IDriverProfileRepository>(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
