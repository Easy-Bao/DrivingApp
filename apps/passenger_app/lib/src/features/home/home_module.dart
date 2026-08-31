import 'dart:async';
import 'package:maps/maps.dart';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger_app/src/features/home/data/data_sources/current_location_data_source.dart';
import 'package:passenger_app/src/features/home/data/data_sources/home_remote_data_source.dart';
import 'package:passenger_app/src/features/home/data/data_sources/public_driver_remote_data_source.dart';
import 'package:passenger_app/src/features/home/data/repositories/current_location_repository_impl.dart';
import 'package:passenger_app/src/features/home/data/repositories/home_repository_impl.dart';
import 'package:passenger_app/src/features/home/data/repositories/public_driver_summary_repository_impl.dart';
import 'package:passenger_app/src/features/home/domain/repositories/current_location_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/home_repository.dart';
import 'package:passenger_app/src/features/home/domain/repositories/public_driver_summary_repository.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/home/presentation/view/home_page.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/presentation/view/add_category_page.dart';
import 'package:design_system/design_system.dart';

class HomeModule {
  HomeModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<HomeRemoteDataSource>(
        (i) => HomeRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<CurrentLocationDataSource>(
        (_) => DeviceCurrentLocationDataSource(),
      )
      ..addLazySingleton<PublicDriverRemoteDataSource>(
        (i) => PublicDriverRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<HomeRepository>(
        (i) => HomeRepositoryImpl(
          homeRemoteDataSource: i.get<HomeRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<CurrentLocationRepository>(
        (i) => CurrentLocationRepositoryImpl(
          dataSource: i.get<CurrentLocationDataSource>(),
        ),
      )
      ..addLazySingleton<PublicDriverSummaryRepository>(
        (i) => PublicDriverSummaryRepositoryImpl(
          remoteDataSource: i.get<PublicDriverRemoteDataSource>(),
        ),
      )
      ..addFactory<HomeCubit>(
        (i) => HomeCubit(
          repository: i.get<HomeRepository>(),
          currentLocationRepository: i.get<CurrentLocationRepository>(),
        ),
      )
      ..addLazySingleton<PublicDriverSummaryCubit>(
        (i) => PublicDriverSummaryCubit(
          repository: i.get<PublicDriverSummaryRepository>(),
        ),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: HomeRoutes.addCategory,
      HomeRoutes.addCategoryPath,
      child: (context, GoRouterState state) {
        final extra = SafeRouteExtra.asMap(state.extra);
        final place = extra['place'] as Place?;
        final initialLabel = extra['initialLabel'] as String?;
        final initialIconName = extra['initialIconName'] as String?;
        return AddCategoryPage(
          initialPlace: place,
          initialLabel: initialLabel,
          initialIconName: initialIconName,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: HomeRoutes.home,
      HomeRoutes.homePath,
      child: (context, GoRouterState state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => Modular.get<HomeCubit>()),
          BlocProvider(create: (_) => Modular.get<RideHistoryBloc>()),
          BlocProvider(
            create: (_) {
              final cubit = Modular.get<PublicDriverSummaryCubit>();
              unawaited(cubit.load());
              return cubit;
            },
          ),
          // The cubit is a module singleton shared by Home and Profile.
          // Passing it by value keeps route disposal from closing the
          // singleton while a saved-place flow is still in progress.
          BlocProvider<SavedPlacesCubit>.value(
            value: Modular.get<SavedPlacesCubit>(),
          ),
        ],
        child: const HomePage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
