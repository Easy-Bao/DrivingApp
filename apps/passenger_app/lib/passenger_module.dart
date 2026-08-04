import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/activity/activity_module.dart';
import 'package:passenger_app/src/features/activity/data/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/i_activity_repository.dart';
import 'package:passenger_app/src/features/activity/presentation/bloc/activity_bloc.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/passenger_remote_data_source.dart';
import 'package:passenger_app/src/features/chat/chat_module.dart';
import 'package:passenger_app/src/features/home/data/repositories/home_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_passenger_home_repository.dart';
import 'package:passenger_app/src/features/home/home_module.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/home_cubit.dart';
import 'package:passenger_app/src/features/inbox/data/repositories/inbox_repository.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:passenger_app/src/features/inbox/inbox_module.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/profile_module.dart';
import 'package:passenger_app/src/features/saved_places/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/i_saved_places_repository.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger_app/src/features/settings/settings_module.dart';
import 'package:passenger_app/src/features/trip/data/repositories/driver_repository.dart';
import 'package:passenger_app/src/features/trip/data/repositories/track_repository.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/track_driver/track_driver_cubit.dart';
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
      ..addLazySingleton<ActivityBloc>(
        (i) => ActivityBloc(repository: i.get<IActivityRepository>()),
      )
      ..addLazySingleton<InboxCubit>(
        (i) => InboxCubit(inboxRepository: i.get<IInboxRepository>()),
      )
      ..addLazySingleton<HomeCubit>(
        (i) => HomeCubit(repository: i.get<IPassengerHomeRepository>()),
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

    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          PassengerShellLayout(child: child),
      routes: [
        ...HomeModule.shellRoutes,
        ...ActivityModule.shellRoutes,
        ...ProfileModule.shellRoutes,
        ...InboxModule.shellRoutes,
      ],
    ),
  ];
}
