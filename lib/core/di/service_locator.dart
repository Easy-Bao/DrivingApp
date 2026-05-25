import 'package:BaoRide/features/driver/data/repositories/dashboard_repository.dart';
import 'package:BaoRide/features/driver/data/repositories/ride_repository.dart';
import 'package:BaoRide/features/passenger/data/repositories/driver_repository.dart';
import 'package:BaoRide/features/passenger/data/repositories/passenger_home_repository.dart';
import 'package:BaoRide/features/passenger/data/repositories/track_repository.dart';
import 'package:get_it/get_it.dart';

/// Global service locator instance.
///
/// **One-line switch from mock → real backend:**
/// Change a single registration here — every Cubit, Bloc, and test that
/// depends on the abstract interface automatically gets the new implementation.
///
/// Example:
/// ```dart
/// // 🟢 NOW: Mock data
/// getIt.registerLazySingleton<DashboardRepository>(() => MockDashboardRepository());
///
/// // 🔴 BACKEND READY: Swap to this
/// getIt.registerLazySingleton<DashboardRepository>(() => ApiDashboardRepository(httpClient));
/// ```
final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // ── Driver Feature Repositories ───────────────────────────────────────────
  // 🟢 Mock data. Swap to ApiDashboardRepository when backend is ready.
  getIt.registerLazySingleton<DashboardRepository>(
    () => MockDashboardRepository(),
  );

  // 🟢 Rust FFI implementation. Swap to ApiRideRepository when backend is ready.
  getIt.registerLazySingleton<RideRepository>(() => RideRepositoryImpl());

  // ── Passenger Feature Repositories ───────────────────────────────────────
  // 🟢 Mock data. Swap to RustDriverRepository or ApiDriverRepository when ready.
  getIt.registerLazySingleton<DriverRepository>(() => MockDriverRepository());

  // 🟢 Mock straight-line route. Swap to MapboxTrackRepository when live tracking lands.
  getIt.registerLazySingleton<TrackRepository>(() => MockTrackRepository());

  // 🟢 Mock home data. Swap to ApiPassengerHomeRepository when backend is ready.
  getIt.registerLazySingleton<PassengerHomeRepository>(
    () => MockPassengerHomeRepository(),
  );
}
