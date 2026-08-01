import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Activity/ActivityModule.dart';
import 'package:passenger_app/src/Features/Activity/Data/Repositories/ActivityRepository.dart';
import 'package:passenger_app/src/Features/Activity/Domain/Repositories/IActivityRepository.dart';
import 'package:passenger_app/src/Features/Activity/Presentation/Bloc/ActivityBloc.dart';
import 'package:passenger_app/src/Features/Chat/ChatModule.dart';
import 'package:passenger_app/src/Features/Home/Data/Repositories/HomeRepository.dart';
import 'package:passenger_app/src/Features/Home/Domain/Repositories/IPassengerHomeRepository.dart';
import 'package:passenger_app/src/Features/Home/HomeModule.dart';
import 'package:passenger_app/src/Features/Home/Presentation/Bloc/HomeCubit.dart';
import 'package:passenger_app/src/Features/Trip/Domain/Repositories/IDriverRepository.dart';
import 'package:passenger_app/src/Features/Trip/Domain/Repositories/ITrackRepository.dart';
import 'package:passenger_app/src/Features/Inbox/Data/Repositories/InboxRepository.dart';
import 'package:passenger_app/src/Features/Inbox/Domain/Repositories/IInboxRepository.dart';
import 'package:passenger_app/src/Features/Inbox/InboxModule.dart';
import 'package:passenger_app/src/Features/Inbox/Presentation/Bloc/InboxCubit.dart';
import 'package:passenger_app/src/Features/Profile/Presentation/Bloc/ProfileCubit.dart';
import 'package:passenger_app/src/Features/Profile/ProfileModule.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Data/Repositories/SavedPlacesRepository.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Domain/Repositories/ISavedPlacesRepository.dart';
import 'package:passenger_app/src/Features/SavedPlaces/Presentation/Bloc/SavedPlacesCubit.dart';
import 'package:passenger_app/src/Features/Settings/SettingsModule.dart';
import 'package:passenger_app/src/Features/Trip/Data/Repositories/DriverRepository.dart';
import 'package:passenger_app/src/Features/Trip/Data/Repositories/TrackRepository.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/BookingBloc.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/LiveMap/LiveMapBloc.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/TrackDriver/TrackDriverCubit.dart';
import 'package:passenger_app/src/Features/Trip/TripModule.dart';
import 'package:passenger_app/src/Shared/Widgets/Navigationbar/PassengerTab.dart';
import 'package:passenger_app/src/Core/Services/SecureSessionService.dart';
import 'package:passenger_app/src/Features/Booking/Data/DataSources/BiddingRemoteDataSource.dart';
import 'package:passenger_app/src/Features/Booking/Data/DataSources/PassengerRemoteDataSource.dart';


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
        ),
      )
      ..addLazySingleton<ISavedPlacesRepository>(
        (i) => SavedPlacesRepository(),
      )
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
      ..addFactory<BookingBloc>(
        (i) => BookingBloc(
          driverRepository: i.get<IDriverRepository>(),
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
          remoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )

      ..addFactory<TrackDriverCubit>(
        (i) => TrackDriverCubit(
          repository: i.get<ITrackRepository>(),
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
