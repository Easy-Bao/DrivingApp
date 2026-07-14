import 'package:core_models/core_models.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/src/core/config/environment_config.dart';
import 'package:passenger_app/src/core/services/bid_session_service.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/trip_booking/data/repositories/activity_repository_impl.dart';
import 'package:passenger_app/src/features/trip_booking/data/repositories/driver_repository_impl.dart';
import 'package:passenger_app/src/features/trip_booking/data/repositories/passenger_home_repository_impl.dart';
import 'package:passenger_app/src/features/trip_booking/data/repositories/saved_places_repository_impl.dart';
import 'package:passenger_app/src/features/trip_booking/data/repositories/track_repository_impl.dart';
import 'package:passenger_app/src/features/trip_booking/domain/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/trip_booking/domain/repositories/saved_places_repository.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/activity/activity_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/passenger_home_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/saved_places_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/profile/profile_cubit.dart';

/// Dependency injection registry and service locator configuration.
final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<SecureSessionService>(
    () => SecureSessionService(),
  );

  getIt.registerLazySingleton<PassengerApiService>(
    () => PassengerApiService(baseUrl: EnvironmentConfig.passengerServiceUri),
  );

  getIt.registerLazySingleton<DriverRepository>(
    () => DriverRepositoryImpl(apiService: getIt<PassengerApiService>()),
  );

  getIt.registerLazySingleton<TrackRepository>(
    () => TrackRepositoryImpl(apiService: getIt<PassengerApiService>()),
  );

  getIt.registerLazySingleton<PassengerHomeRepository>(
    () => PassengerHomeRepositoryImpl(apiService: getIt<PassengerApiService>()),
  );

  getIt.registerLazySingleton<SavedPlacesRepository>(
    () => SavedPlacesRepositoryImpl(),
  );

  getIt.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(apiService: getIt<PassengerApiService>()),
  );

  getIt.registerFactory<SavedPlacesCubit>(
    () => SavedPlacesCubit(repository: getIt<SavedPlacesRepository>()),
  );

  getIt.registerFactory<ActivityBloc>(
    () => ActivityBloc(repository: getIt<ActivityRepository>()),
  );

  getIt.registerLazySingleton<BidSessionService>(
    () => BidSessionService(apiService: getIt<PassengerApiService>()),
  );

  getIt.registerFactory<BookingBloc>(
    () => BookingBloc(
      driverRepository: getIt<DriverRepository>(),
      bidSessionService: getIt<BidSessionService>(),
      apiService: getIt<PassengerApiService>(),
    ),
  );

  getIt.registerFactory<LiveMapBloc>(
    () => LiveMapBloc(apiService: getIt<PassengerApiService>()),
  );

  getIt.registerFactory<ProfileCubit>(() => ProfileCubit());

  getIt.registerFactory<PassengerHomeCubit>(
    () => PassengerHomeCubit(repository: getIt<PassengerHomeRepository>()),
  );
}
