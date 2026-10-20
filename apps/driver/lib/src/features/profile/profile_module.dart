import 'dart:async';

import 'package:dio/dio.dart';
import 'package:driver/src/features/auth/domain/services/driver_logout_coordinator.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/data/data_sources/driver_profile_remote_data_source.dart';
import 'package:driver/src/features/profile/data/data_sources/driver_document_remote_data_source.dart';
import 'package:driver/src/features/profile/data/repositories/driver_document_repository_impl.dart';
import 'package:driver/src/features/profile/data/repositories/driver_profile_repository_impl.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_document_repository.dart';
import 'package:driver/src/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:driver/src/features/profile/profile_routes.dart';
import 'package:driver/src/features/profile/presentation/view/driver_account_page.dart';
import 'package:driver/src/features/profile/presentation/view/driver_personal_details_page.dart';
import 'package:driver/src/features/profile/presentation/view/driver_vehicle_information_page.dart';
import 'package:driver/src/features/profile/presentation/bloc/document_upload/driver_document_upload_cubit.dart';
import 'package:driver/src/features/profile/presentation/view/driver_document_upload_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:design_system/design_system.dart';

class ProfileModule._() {
  static void binds(Injector i) {
    i
      ..addLazySingleton<ProfileRemoteDataSource>(
        (i) => ProfileRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DocumentRemoteDataSource>(
        (i) => DocumentRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DocumentRepository>(
        (i) => DocumentRepositoryImpl(i.get<DocumentRemoteDataSource>()),
      )
      ..addLazySingleton<ProfileRepository>(
        (i) => ProfileRepositoryImpl(
          profileDataSource: i.get<ProfileRemoteDataSource>(),
          sessionService: i.get<SessionStore>(),
          preferences: i.get<SharedPreferences>(),
        ),
      )
      ..addFactory<AccountCubit>(
        (i) => AccountCubit(repository: i.get<ProfileRepository>()),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ProfileRoutes.personalDetails,
      ProfileRoutes.personalDetailsPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<AccountCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const PersonalDetailsPage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ProfileRoutes.vehicleInformation,
      ProfileRoutes.vehicleInformationPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<AccountCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const VehicleInformationPage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ProfileRoutes.documents,
      ProfileRoutes.documentsPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) => DocumentUploadCubit(Modular.get<DocumentRepository>()),
        child: const DocumentUploadPage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> accountShellRoutes = [
    ChildRoute(
      name: ProfileRoutes.account,
      ProfileRoutes.accountPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<AccountCubit>();
          cubit.load();
          return cubit;
        },
        child: AccountPage(onLogout: Modular.get<LogoutCoordinator>().logout),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
