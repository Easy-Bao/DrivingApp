import 'package:core_models/core_models.dart';
import 'package:driver_app/features/driver/data/repositories/dashboard_repository_impl.dart';
import 'package:driver_app/features/driver/data/repositories/ride_repository_impl.dart';
import 'package:driver_app/features/driver/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:get_it/get_it.dart';

/**
 * Global service locator instance.
 *
 * Switch registrations globally between mock repositories and their live API
 * implementations. Any depending cubit, bloc, or widget consumes
 * the injected singleton seamlessly via constructor parameter injection.
 */
final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(),
  );
  getIt.registerLazySingleton<RideRepository>(() => RideRepositoryImpl());
  getIt.registerLazySingleton<DashboardCubit>(
    () => DashboardCubit(repository: getIt<DashboardRepository>()),
  );
}
