import 'package:core_models/core_models.dart';
import 'package:driver_app/features/driver/data/repositories/dashboard_repository.dart';
import 'package:driver_app/features/driver/data/repositories/ride_repository.dart';
import 'package:get_it/get_it.dart';

/**
 * Global service locator instance.
 *
 * Switch registrations globally between mock repositories and their Rust FFI
 * or live API implementations. Any depending cubit, bloc, or widget consumes
 * the injected singleton seamlessly via constructor parameter injection.
 */
final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Driver Feature Repositories
  // Wired to live backend via GET /drivers/:id/stats.
  getIt.registerLazySingleton<DashboardRepository>(
    () => ApiDashboardRepository(),
  );

  // Live API implementation.
  getIt.registerLazySingleton<RideRepository>(() => ApiRideRepository());
}
