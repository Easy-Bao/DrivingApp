import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/profile/presentation/screens/help_center_screen.dart';
import 'package:passenger_app/src/features/profile/presentation/screens/passenger_account_screen.dart';
import 'package:passenger_app/src/features/profile/presentation/screens/profile_info_screen.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/presentation/screens/saved_place_screen.dart';
import 'package:shared_ui/shared_ui.dart';

class ProfileModule {
  ProfileModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ProfileRoutes.profileInfo,
      'account/profile-info',
      child: (context, GoRouterState state) => const ProfileInfoScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ProfileRoutes.helpCenter,
      'account/help-center',
      child: (context, GoRouterState state) => const HelpCenterScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ProfileRoutes.help,
      'help',
      child: (context, GoRouterState state) => BlocProvider<SavedPlacesCubit>(
        create: (_) => Modular.get<SavedPlacesCubit>(),
        child: const SavedPlaceScreen(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ProfileRoutes.account,
      'account',
      child: (context, GoRouterState state) => const PassengerAccountScreen(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
