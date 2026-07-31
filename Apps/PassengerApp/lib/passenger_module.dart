import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Activity/ActivityModule.dart';
import 'package:passenger_app/src/Features/Activity/Data/Repositories/ActivityRepositoryImpl.dart';
import 'package:passenger_app/src/Features/Activity/Domain/Repositories/ActivityRepository.dart';
import 'package:passenger_app/src/Features/Activity/Presentation/Bloc/ActivityBloc.dart';
import 'package:passenger_app/src/Features/Chat/ChatModule.dart';
import 'package:passenger_app/src/Features/Home/Data/Repositories/HomeRepositoryImpl.dart';
import 'package:passenger_app/src/Features/Home/HomeModule.dart';
import 'package:passenger_app/src/Features/Home/Presentation/Bloc/HomeCubit.dart';
import 'package:passenger_app/src/Features/Inbox/Data/Repositories/InboxRepositoryImpl.dart';
import 'package:passenger_app/src/Features/Inbox/Domain/Repositories/InboxRepository.dart';
import 'package:passenger_app/src/Features/Inbox/InboxModule.dart';
import 'package:passenger_app/src/Features/Inbox/Presentation/Bloc/InboxCubit.dart';
import 'package:passenger_app/src/Features/Profile/Presentation/Bloc/ProfileCubit.dart';
import 'package:passenger_app/src/Features/Profile/ProfileModule.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Data/Repositories/SavedPlacesRepositoryImpl.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Domain/Repositories/SavedPlacesRepository.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Presentation/Bloc/SavedPlacesCubit.dart';
import 'package:passenger_app/src/Features/Settings/SettingsModule.dart';
import 'package:passenger_app/src/Features/Trip/Data/Repositories/DriverRepositoryImpl.dart';
import 'package:passenger_app/src/Features/Trip/Data/Repositories/TrackRepositoryImpl.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/BookingBloc.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/LiveMap/LiveMapBloc.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/TrackDriver/TrackDriverCubit.dart';
import 'package:passenger_app/src/Features/Trip/TripModule.dart';
import 'package:passenger_app/src/Shared/Widgets/Navigationbar/PassengerTab.dart';
import 'package:passenger_app/src/Core/Services/Securesessionservice.dart';
import 'package:passenger_app/src/Features/Booking/Data/DataSources/BiddingRemoteDataSource.dart';


class PassengerModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<DriverRepository>(
        (i) => DriverRepositoryImpl(
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<TrackRepository>(
        (i) => TrackRepositoryImpl(
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<PassengerHomeRepository>(
        (i) => HomeRepositoryImpl(
          passengerRemoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<SavedPlacesRepository>(
        (i) => SavedPlacesRepositoryImpl(),
      )
      ..addLazySingleton<ActivityRepository>(
        (i) => ActivityRepositoryImpl(
          passengerRemoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<InboxRepository>(
        (i) => InboxRepositoryImpl(
          remoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<SavedPlacesCubit>(
        (i) => SavedPlacesCubit(repository: i.get<SavedPlacesRepository>()),
      )
      ..addLazySingleton<ActivityBloc>(
        (i) => ActivityBloc(repository: i.get<ActivityRepository>()),
      )
      ..addLazySingleton<InboxCubit>(
        (i) => InboxCubit(inboxRepository: i.get<InboxRepository>()),
      )
      ..addLazySingleton<HomeCubit>(
        (i) => HomeCubit(repository: i.get<PassengerHomeRepository>()),
      )
      ..addFactory<BookingBloc>(
        (i) => BookingBloc(
          driverRepository: i.get<DriverRepository>(),
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )

      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addFactory<ProfileCubit>(
        (i) => ProfileCubit(
          profileRepository: i.get<PassengerProfileRepository>(),
        ),
      )
      ..addFactory<TrackDriverCubit>(
        (i) => TrackDriverCubit(
          repository: i.get<TrackRepository>(),
          sessionService: i.get<SecureSessionService>(),
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
