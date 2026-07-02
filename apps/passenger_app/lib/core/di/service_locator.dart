/// Service Locator: handles dependency injection registration for repositories and state management units.
library;

import 'package:core_models/core_models.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/passenger/data/repositories/activity_repository.dart';
import 'package:passenger_app/features/passenger/data/repositories/driver_repository.dart';
import 'package:passenger_app/features/passenger/data/repositories/local_saved_places_repository.dart';
import 'package:passenger_app/features/passenger/data/repositories/local_passenger_home_repository.dart';
import 'package:passenger_app/features/passenger/data/repositories/local_track_repository.dart';
import 'package:passenger_app/features/passenger/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/activity/activity_bloc.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/saved_places_cubit.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DriverRepository>(() => ApiDriverRepository());
  getIt.registerLazySingleton<TrackRepository>(() => LocalTrackRepository());
  getIt.registerLazySingleton<PassengerHomeRepository>(
    () => LocalPassengerHomeRepository(),
  );
  getIt.registerLazySingleton<SavedPlacesRepository>(
    () => LocalSavedPlacesRepository(),
  );
  getIt.registerLazySingleton<ActivityRepository>(
    () => ApiActivityRepository(),
  );
  getIt.registerFactory<SavedPlacesCubit>(
    () => SavedPlacesCubit(repository: getIt<SavedPlacesRepository>()),
  );
  getIt.registerFactory<ActivityBloc>(
    () => ActivityBloc(repository: getIt<ActivityRepository>()),
  );
}
