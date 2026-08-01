import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Profile/Presentation/Screens/AccountScreen.dart';
import 'package:passenger_app/src/Features/Profile/Presentation/Screens/HelpCenterScreen.dart';
import 'package:passenger_app/src/Features/Profile/Presentation/Screens/ProfileInfoScreen.dart';
import 'package:passenger_app/src/Features/Profile/ProfileRoutes.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Presentation/Bloc/SavedPlacesCubit.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Presentation/Screens/SavedPlaceScreen.dart';
import 'package:shared_ui/SharedUi.dart';

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
      child: (context, GoRouterState state) => const AccountScreen(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
