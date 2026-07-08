/// Service Locator: handles dependency injection registration for repositories and state management units.
library;

import 'package:core_models/core_models.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/passenger/data/repositories/activity_repository.dart';
import 'package:passenger_app/features/passenger/data/repositories/activity_repository_impl.dart';
import 'package:passenger_app/features/passenger/data/repositories/driver_repository_impl.dart';
import 'package:passenger_app/features/passenger/data/repositories/saved_places_repository_impl.dart';
import 'package:passenger_app/features/passenger/data/repositories/passenger_home_repository_impl.dart';
import 'package:passenger_app/features/passenger/data/repositories/track_repository_impl.dart';
import 'package:passenger_app/features/passenger/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/activity/activity_bloc.dart';
import 'package:passenger_app/core/services/bid_session_service.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/saved_places_cubit.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DriverRepository>(() => DriverRepositoryImpl());
  getIt.registerLazySingleton<TrackRepository>(() => TrackRepositoryImpl());
  getIt.registerLazySingleton<PassengerHomeRepository>(
    () => PassengerHomeRepositoryImpl(),
  );
  getIt.registerLazySingleton<SavedPlacesRepository>(
    () => SavedPlacesRepositoryImpl(),
  );
  getIt.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(),
  );
  getIt.registerFactory<SavedPlacesCubit>(
    () => SavedPlacesCubit(repository: getIt<SavedPlacesRepository>()),
  );
  getIt.registerFactory<ActivityBloc>(
    () => ActivityBloc(repository: getIt<ActivityRepository>()),
  );
  getIt.registerLazySingleton<BidSessionService>(() => BidSessionService());
}
