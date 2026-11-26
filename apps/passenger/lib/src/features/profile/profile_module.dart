import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:passenger/src/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:passenger/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:passenger/src/features/profile/presentation/pages/account_page.dart';
import 'package:passenger/src/features/profile/presentation/pages/profile_info_page.dart';
import 'package:passenger/src/features/profile/profile_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileModule._() {
  static void binds(Injector i) {
    i
      ..addLazySingleton<ProfileRemoteDataSource>(
        (i) => ProfileRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<ProfileRepository>(
        (i) => ProfileRepositoryImpl(
          remoteDataSource: i.get<ProfileRemoteDataSource>(),
          sessionService: i.get<SessionStore>(),
          preferences: i.get<SharedPreferences>(),
        ),
      )
      ..addLazySingleton<ProfileCubit>(
        (i) => ProfileCubit(repository: i.get<ProfileRepository>()),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ProfileRoutes.profileInfo,
      ProfileRoutes.profileInfoPath,
      child: (context, GoRouterState state) => BlocProvider<ProfileCubit>.value(
        value: Modular.get<ProfileCubit>(),
        child: const _ProfileRouteLoader(child: ProfileInfoPage()),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ProfileRoutes.account,
      ProfileRoutes.accountPath,
      child: (context, GoRouterState state) => BlocProvider<ProfileCubit>.value(
        value: Modular.get<ProfileCubit>(),
        child: _ProfileRouteLoader(
          child: AccountPage(
            onLogout: () =>
                BlocProvider.of<SessionBloc>(context)
                    .add(const SessionLogoutRequested()),
          ),
        ),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

class _ProfileRouteLoader extends StatefulWidget {
  const _ProfileRouteLoader({required this.child});

  final Widget child;

  @override
  State<_ProfileRouteLoader> createState() => _ProfileRouteLoaderState();
}

class _ProfileRouteLoaderState extends State<_ProfileRouteLoader> {
  @override
  void initState() {
    super.initState();
    unawaited(BlocProvider.of<ProfileCubit>(context).loadProfile());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
