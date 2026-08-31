import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/data/data_sources/passenger_profile_remote_data_source.dart';
import 'package:passenger_app/src/features/profile/data/repositories/passenger_profile_repository.dart';
import 'package:passenger_app/src/features/profile/domain/repositories/i_passenger_profile_repository.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/features/profile/presentation/view/account_page.dart';
import 'package:passenger_app/src/features/profile/presentation/view/help_center_page.dart';
import 'package:passenger_app/src/features/profile/presentation/view/profile_info_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:design_system/design_system.dart';

class ProfileModule {
  ProfileModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<PassengerProfileRemoteDataSource>(
        (i) => PassengerProfileRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<IPassengerProfileRepository>(
        (i) => PassengerProfileRepository(
          remoteDataSource: i.get<PassengerProfileRemoteDataSource>(),
          sessionService: i.get<PassengerSessionStore>(),
          preferences: i.get<SharedPreferences>(),
        ),
      )
      ..addFactory<ProfileCubit>(
        (i) => ProfileCubit(repository: i.get<IPassengerProfileRepository>()),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ProfileRoutes.profileInfo,
      ProfileRoutes.profileInfoPath,
      child: (context, GoRouterState state) => BlocProvider<ProfileCubit>(
        create: (_) {
          final cubit = Modular.get<ProfileCubit>();
          unawaited(cubit.loadProfile());
          return cubit;
        },
        child: const ProfileInfoPage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ProfileRoutes.helpCenter,
      ProfileRoutes.helpCenterPath,
      child: (context, GoRouterState state) => const HelpCenterPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ProfileRoutes.account,
      ProfileRoutes.accountPath,
      child: (context, GoRouterState state) => BlocProvider<ProfileCubit>(
        create: (_) {
          final cubit = Modular.get<ProfileCubit>();
          unawaited(cubit.loadProfile());
          return cubit;
        },
        child: AccountPage(
          onLogout: () => BlocProvider.of<SessionBloc>(
            context,
          ).add(const SessionLogoutRequested()),
        ),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
