import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Home/HomeRoutes.dart';
import 'package:passenger_app/src/Features/Home/Presentation/Bloc/HomeCubit.dart';
import 'package:passenger_app/src/Features/Home/Presentation/Screens/HomeScreen.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Domain/Entities/SavedPlace.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Presentation/Bloc/SavedPlacesCubit.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Presentation/Screens/AddCategoryScreen.dart';
import 'package:shared_ui/shared_ui.dart';

class HomeModule {
  HomeModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: HomeRoutes.addCategory,
      'home/add-category',
      child: (context, GoRouterState state) {
        final extra = SafeRouteExtra.asMap(state.extra);
        final onSave = extra['onSave'] as Function(SavedPlace)?;
        final place = extra['place'] as PlaceModel?;
        final initialLabel = extra['initialLabel'] as String?;
        return AddCategoryScreen(
          onSave: onSave ?? (_) {},
          initialPlace: place,
          initialLabel: initialLabel,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: HomeRoutes.home,
      'home',
      child: (context, GoRouterState state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => Modular.get<HomeCubit>()),
          BlocProvider(
            create: (_) {
              final cubit = Modular.get<SavedPlacesCubit>();
              unawaited(cubit.loadPlaces());
              return cubit;
            },
          ),
        ],
        child: const HomeScreen(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
