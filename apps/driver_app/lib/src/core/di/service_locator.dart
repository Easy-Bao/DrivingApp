import 'package:core_models/core_models.dart';
import 'package:driver_app/src/core/config/environment_config.dart';
import 'package:driver_app/src/core/services/driver_api_service.dart';
import 'package:driver_app/src/features/driver_dispatch/data/repositories/dashboard_repository_impl.dart';
import 'package:driver_app/src/features/driver_dispatch/data/repositories/ride_repository_impl.dart';
import 'package:driver_app/src/features/driver_dispatch/domain/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/driver_dispatch/data/repositories/driver_activity_repository_impl.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_bloc.dart';
import 'package:get_it/get_it.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Sets up global dependency registrations for constructor injection.
void setupServiceLocator() {
  getIt.registerLazySingleton<DriverApiService>(
    () => DriverApiService(baseUrl: EnvironmentConfig.driverServiceUri),
  );

  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(apiService: getIt<DriverApiService>()),
  );

  getIt.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(apiService: getIt<DriverApiService>()),
  );

  getIt.registerLazySingleton<DriverActivityRepository>(
    () => DriverActivityRepositoryImpl(apiService: getIt<DriverApiService>()),
  );

  getIt.registerLazySingleton<DashboardCubit>(
    () => DashboardCubit(repository: getIt<DashboardRepository>()),
  );

  getIt.registerFactory<LiveMapBloc>(() => LiveMapBloc());
}
