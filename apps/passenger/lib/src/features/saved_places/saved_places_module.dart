import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/saved_places/data/repositories/saved_places_repository_impl.dart';
import 'package:passenger/src/features/saved_places/domain/repositories/saved_places_repository.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/pages/add_saved_place_page.dart';
import 'package:passenger/src/features/saved_places/presentation/pages/saved_places_page.dart';
import 'package:passenger/src/features/saved_places/saved_places_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPlacesModule._() {
  static void binds(Injector i) {
    i
      ..addLazySingleton<SavedPlacesRepository>(
        (i) =>
            SavedPlacesRepositoryImpl(preferences: i.get<SharedPreferences>()),
      )
      ..addLazySingleton<SavedPlacesCubit>(
        (i) => SavedPlacesCubit(repository: i.get<SavedPlacesRepository>()),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: SavedPlacesRoutes.places,
      SavedPlacesRoutes.placesPath,
      child: (context, GoRouterState state) =>
          BlocProvider<SavedPlacesCubit>.value(
            value: Modular.get<SavedPlacesCubit>(),
            child: const SavedPlacePage(),
          ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: SavedPlacesRoutes.addCategory,
      SavedPlacesRoutes.addCategoryPath,
      child: (context, GoRouterState state) {
        final extra = SafeRouteExtra.asMap(state.extra);
        final place = extra['place'] as Place?;
        final initialLabel = extra['initialLabel'] as String?;
        final initialIconName = extra['initialIconName'] as String?;
        return AddCategoryPage(
          initialPlace: place,
          initialLabel: initialLabel,
          initialIconName: initialIconName,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}
