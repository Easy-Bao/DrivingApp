import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/data/data_sources/inbox_remote_data_source.dart';
import 'package:passenger/src/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:passenger/src/features/inbox/inbox_routes.dart';
import 'package:passenger/src/features/inbox/presentation/view/inbox_page.dart';
import 'package:design_system/design_system.dart';

class InboxModule {
  InboxModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<InboxRemoteDataSource>(
        (i) => InboxRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<InboxRepository>(
        (i) => InboxRepositoryImpl(
          remoteDataSource: i.get<InboxRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<InboxCubit>(
        (i) => InboxCubit(inboxRepository: i.get<InboxRepository>()),
      );
  }

  static List<ModularRoute> routes = [];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: InboxRoutes.inbox,
      InboxRoutes.inboxPath,
      child: (context, GoRouterState state) => const InboxPage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
