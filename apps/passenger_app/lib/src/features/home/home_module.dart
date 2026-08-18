import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/activity/bloc/activity/activity_bloc.dart';
import 'package:passenger_app/src/features/home/bloc/home/home_cubit.dart';
import 'package:passenger_app/src/features/home/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/home/view/home_page.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/view/add_category_page.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class HomeModule {
  HomeModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: HomeRoutes.addCategory,
      HomeRoutes.addCategoryPath,
      child: (context, GoRouterState state) {
        final extra = SafeRouteExtra.asMap(state.extra);
        final onSave = extra['onSave'] as Function(SavedPlace)?;
        final place = extra['place'] as PlaceModel?;
        final initialLabel = extra['initialLabel'] as String?;
        return AddCategoryPage(
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
      HomeRoutes.homePath,
      child: (context, GoRouterState state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => Modular.get<HomeCubit>()),
          BlocProvider(create: (_) => Modular.get<ActivityBloc>()),
          BlocProvider(
            create: (_) {
              final cubit = Modular.get<PublicDriverSummaryCubit>();
              unawaited(cubit.load());
              return cubit;
            },
          ),
          BlocProvider(
            create: (_) {
              final cubit = Modular.get<SavedPlacesCubit>();
              unawaited(cubit.loadPlaces());
              return cubit;
            },
          ),
        ],
        child: const HomePage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
