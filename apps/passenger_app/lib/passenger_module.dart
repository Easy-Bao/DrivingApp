import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/activity/activity_module.dart';
import 'package:passenger_app/src/features/activity/bloc/activity/activity_bloc.dart';
import 'package:passenger_app/src/features/activity/data/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/i_activity_repository.dart';
import 'package:passenger_app/src/features/chat/chat_module.dart';
import 'package:passenger_app/src/features/home/bloc/home/home_cubit.dart';
import 'package:passenger_app/src/features/home/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger_app/src/features/home/data/datasources/current_location_data_source.dart';
import 'package:passenger_app/src/features/home/data/repositories/current_location_repository.dart';
import 'package:passenger_app/src/features/home/data/repositories/home_repository.dart';
import 'package:passenger_app/src/features/home/data/repositories/public_driver_summary_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_current_location_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_passenger_home_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_public_driver_summary_repository.dart';
import 'package:passenger_app/src/features/home/home_module.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/data/repositories/inbox_repository.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:passenger_app/src/features/inbox/inbox_module.dart';
import 'package:passenger_app/src/features/location/location_module.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/profile_module.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/i_saved_places_repository.dart';
import 'package:passenger_app/src/features/settings/settings_module.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/datasources/passenger_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/repositories/driver_repository.dart';
import 'package:passenger_app/src/features/trip/data/repositories/track_repository.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:passenger_app/src/features/trip/trip_module.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_tab.dart';

class PassengerModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<IDriverRepository>(
        (i) => DriverRepository(
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<ITrackRepository>(
        (i) => TrackRepository(
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<IPassengerHomeRepository>(
        (i) => HomeRepository(
          passengerRemoteDataSource: i.get<PassengerRemoteDataSource>(),
          secureSessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addLazySingleton<CurrentLocationDataSource>(
        (i) => DeviceCurrentLocationDataSource(),
      )
      ..addLazySingleton<ICurrentLocationRepository>(
        (i) => CurrentLocationRepository(
          dataSource: i.get<CurrentLocationDataSource>(),
        ),
      )
      ..addLazySingleton<IPublicDriverSummaryRepository>(
        (i) => PublicDriverSummaryRepository(
          remoteDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<ISavedPlacesRepository>((i) => SavedPlacesRepository())
      ..addLazySingleton<IActivityRepository>(
        (i) => ActivityRepository(
          passengerRemoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<IInboxRepository>(
        (i) => InboxRepository(
          remoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<SavedPlacesCubit>(
        (i) => SavedPlacesCubit(repository: i.get<ISavedPlacesRepository>()),
      )
      ..addFactory<ActivityBloc>(
        (i) => ActivityBloc(repository: i.get<IActivityRepository>()),
      )
      ..addLazySingleton<InboxCubit>(
        (i) => InboxCubit(inboxRepository: i.get<IInboxRepository>()),
      )
      ..addFactory<HomeCubit>(
        (i) => HomeCubit(
          repository: i.get<IPassengerHomeRepository>(),
          currentLocationRepository: i.get<ICurrentLocationRepository>(),
        ),
      )
      ..addLazySingleton<PublicDriverSummaryCubit>(
        (i) => PublicDriverSummaryCubit(
          repository: i.get<IPublicDriverSummaryRepository>(),
        ),
      )
      ..addLazySingleton<BookingBloc>(
        (i) => BookingBloc(
          driverRepository: i.get<IDriverRepository>(),
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
          secureSessionService: i.get<SecureSessionService>(),
          inboxCubit: i.get<InboxCubit>(),
          backgroundTelemetryService: i.get<BackgroundTelemetryService>(),
        ),
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(biddingDataSource: i.get<BiddingRemoteDataSource>()),
      )
      ..addFactory<ProfileCubit>(
        (i) => ProfileCubit(
          remoteDataSource: i.get<PassengerRemoteDataSource>(),
          secureSessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addFactory<TrackDriverCubit>(
        (i) => TrackDriverCubit(
          repository: i.get<ITrackRepository>(),
          sessionService: i.get<SecureSessionService>(),
          backgroundTelemetryService: i.get<BackgroundTelemetryService>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ...ActivityModule.routes,
    ...TripModule.routes,
    ...ChatModule.routes,
    ...ProfileModule.routes,
    ...SettingsModule.routes,
    ...LocationModule.routes,

    ShellModularRoute(
      builder: (context, GoRouterState state, child) => PassengerShellLayout(
        inboxCubit: Modular.get<InboxCubit>(),
        child: child,
      ),
      routes: [
        ...HomeModule.shellRoutes,
        ...ActivityModule.shellRoutes,
        ...ProfileModule.shellRoutes,
        ...InboxModule.shellRoutes,
      ],
    ),
  ];
}
