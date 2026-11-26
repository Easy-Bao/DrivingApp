import 'package:chat/chat.dart';
import 'package:core_domain/core_domain.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/data/datasources/ride_remote_data_source.dart';
import 'package:passenger/src/features/active_ride/data/repositories/track_repository_impl.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/track_driver_page.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/track_driver_page_loader.dart';

class ActiveRideModule._() {
  static void binds(Injector i) {
    i
      ..addLazySingleton<RideRemoteDataSource>(
        (i) => RideRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<TrackRepository>(
        (i) => TrackRepositoryImpl(
          remoteDataSource: i.get<RideRemoteDataSource>(),
        ),
      );
  }

  static List<ModularRoute> routes({required VoidCallback onRideTerminated}) =>
      [
        ChildRoute(
          name: ActiveRideRoutes.trackDriver,
          ActiveRideRoutes.trackDriverPath,
          child: (context, GoRouterState state) {
            final extra = state.extra;
            final ride = switch (extra) {
              final RideSnapshot snapshot => snapshot,
              final Map payload => RideSnapshot.fromJson(
                Map<String, dynamic>.from(payload),
              ),
              _ => null,
            };
            if (ride == null) {
              return TrackDriverPageLoader(
                rideId: extra is String ? extra : null,
                trackRepository: Modular.get<TrackRepository>(),
                chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
                sessionService: Modular.get<SessionStore>(),
                lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
                onRideTerminated: onRideTerminated,
                realtimeClient: Modular.get<RealtimeWebSocketClient>(),
              );
            }
            return TrackDriverPage(
              ride: ride,
              trackRepository: Modular.get<TrackRepository>(),
              chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
              sessionService: Modular.get<SessionStore>(),
              lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
              onRideTerminated: onRideTerminated,
              realtimeClient: Modular.get<RealtimeWebSocketClient>(),
            );
          },
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
      ];
}
