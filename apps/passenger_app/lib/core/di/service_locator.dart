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

/**
 * Global service locator instance.
 *
 * Switch registrations globally between mock repositories and their Rust FFI
 * or live API implementations. Any depending cubit, bloc, or widget consumes
 * the injected singleton seamlessly via constructor parameter injection.
 */
final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  /**
   * Pure Dart repository mapping coordinates to nearby available drivers.
   */
  getIt.registerLazySingleton<DriverRepository>(() => LocalDriverRepository());

  /**
   * Pure Dart snapped-to-road routing polyline calculation adapter.
   */
  getIt.registerLazySingleton<TrackRepository>(() => LocalTrackRepository());

  /**
   * Pure Dart reverse geocoding for passenger homepage location tracking.
   */
  getIt.registerLazySingleton<PassengerHomeRepository>(
    () => LocalPassengerHomeRepository(),
  );

  /**
   * SharedPreferences-backed repository persisting the passenger's saved-place
   * shortcut chips across sessions. Registered as a lazy singleton so the same
   * SharedPreferences instance is reused across all reads and writes during a
   * single app session.
   */
  getIt.registerLazySingleton<SavedPlacesRepository>(
    () => LocalSavedPlacesRepository(),
  );

  /**
   * API-backed repository fetching the passenger's ride history from the
   * passenger-service backend. Registered as a lazy singleton because the
   * HTTP client is stateless and safe to share across screen mounts.
   */
  getIt.registerLazySingleton<ActivityRepository>(
    () => ApiActivityRepository(),
  );

  /**
   * Cubit managing the chip row state. Registered as a factory so each
   * PassengerHomeScreen mount receives a fresh cubit instance, preventing
   * stale state from leaking across navigation back-and-forth cycles.
   */
  getIt.registerFactory<SavedPlacesCubit>(
    () => SavedPlacesCubit(repository: getIt<SavedPlacesRepository>()),
  );

  /**
   * BLoC managing the Activity screen's ride list. Registered as a factory
   * so each PassengerActivityScreen mount receives a fresh bloc instance,
   * preventing stale past/upcoming lists from persisting across navigations.
   */
  getIt.registerFactory<ActivityBloc>(
    () => ActivityBloc(repository: getIt<ActivityRepository>()),
  );
}

