import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/i_saved_places_repository.dart';
import 'package:passenger_app/src/features/saved_places/saved_places_routes.dart';
import 'package:passenger_app/src/features/saved_places/presentation/saved_place_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class SavedPlacesModule {
  SavedPlacesModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<ISavedPlacesRepository>(
        (i) => SavedPlacesRepository(preferences: i.get<SharedPreferences>()),
      )
      ..addLazySingleton<SavedPlacesCubit>(
        (i) => SavedPlacesCubit(repository: i.get<ISavedPlacesRepository>()),
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
  ];
}
