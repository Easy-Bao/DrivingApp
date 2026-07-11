import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/driver_dispatch/data/repositories/dashboard_repository_impl.dart';
import 'package:driver_app/src/features/driver_dispatch/data/repositories/ride_repository_impl.dart';
import 'package:driver_app/src/features/driver_dispatch/domain/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/driver_dispatch/data/repositories/driver_activity_repository_impl.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_bloc.dart';
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
  getIt.registerLazySingleton<DriverActivityRepository>(
    () => DriverActivityRepositoryImpl(),
  );
  getIt.registerLazySingleton<DashboardCubit>(
    () => DashboardCubit(repository: getIt<DashboardRepository>()),
  );
  getIt.registerFactory<LiveMapBloc>(
    () => LiveMapBloc(),
  );
}
