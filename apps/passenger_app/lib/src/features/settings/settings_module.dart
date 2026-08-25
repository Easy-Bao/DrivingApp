import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/settings/bloc/settings/settings_cubit.dart';
import 'package:passenger_app/src/features/settings/data/repositories/settings_repository.dart';
import 'package:passenger_app/src/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:passenger_app/src/features/settings/view/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class SettingsModule {
  SettingsModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<ISettingsRepository>(
        (i) => SettingsRepository(preferences: i.get<SharedPreferences>()),
      )
      ..addFactory<SettingsCubit>(
        (i) => SettingsCubit(settingsRepository: i.get<ISettingsRepository>()),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: SettingsRoutes.settings,
      SettingsRoutes.settingsPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<SettingsCubit>();
          unawaited(cubit.loadSettings());
          return cubit;
        },
        child: const SettingsPage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}
