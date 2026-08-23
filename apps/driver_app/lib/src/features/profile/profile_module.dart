import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/profile/view/driver_account_page.dart';
import 'package:driver_app/src/features/activity/view/earnings_page.dart';
import 'package:driver_app/src/features/profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:shared_ui/shared_ui.dart';

class ProfileModule {
  ProfileModule._();

  static void binds(Injector i) {
    i.addLazySingleton<DriverProfileRemoteDataSource>(
      (i) => DriverProfileRemoteDataSourceImpl(i.get<Dio>()),
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
      child: (context, GoRouterState state) => const DriverAccountPage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
