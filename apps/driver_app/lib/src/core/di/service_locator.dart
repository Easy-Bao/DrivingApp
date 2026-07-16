import 'package:core_models/core_models.dart';
import 'package:driver_app/src/core/config/environment_config.dart';
import 'package:driver_app/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:driver_app/src/features/dashboard/data/repositories/driver_activity_repository_impl.dart';
import 'package:driver_app/src/features/dashboard/domain/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/dashboard/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/data/repositories/ride_repository_impl.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_bloc.dart';
import 'package:driver_services/driver_services.dart';
import 'package:get_it/get_it.dart';
import 'package:session_service/session_service.dart';

/// Dependency injection registry and service locator configuration.
final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<SecureSessionService>(
    () => SecureSessionService(),
  );

  getIt.registerLazySingleton<AuthApiService>(
    () => AuthApiService(baseUrl: EnvironmentConfig.driverServiceUri),
  );

  getIt.registerLazySingleton<BiddingApiService>(
    () => BiddingApiService(baseUrl: EnvironmentConfig.driverServiceUri),
  );

  getIt.registerLazySingleton<TripApiService>(
    () => TripApiService(baseUrl: EnvironmentConfig.driverServiceUri),
  );

  getIt.registerLazySingleton<TelemetryApiService>(
    () => TelemetryApiService(baseUrl: EnvironmentConfig.driverServiceUri),
  );

  getIt.registerLazySingleton<PassengerApiService>(
    () => PassengerApiService(baseUrl: EnvironmentConfig.driverServiceUri),
  );

  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(apiService: getIt<TripApiService>()),
  );

  getIt.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(apiService: getIt<BiddingApiService>()),
  );

  getIt.registerLazySingleton<DriverActivityRepository>(
    () => DriverActivityRepositoryImpl(apiService: getIt<TripApiService>()),
  );

  getIt.registerLazySingleton<DashboardCubit>(
    () => DashboardCubit(repository: getIt<DashboardRepository>()),
  );

  getIt.registerFactory<LiveMapBloc>(
    () => LiveMapBloc(
      telemetryService: getIt<TelemetryApiService>(),
      sessionService: getIt<SecureSessionService>(),
    ),
  );
}
