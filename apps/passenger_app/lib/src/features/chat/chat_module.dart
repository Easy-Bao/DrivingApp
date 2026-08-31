import 'package:dio/dio.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/chat/chat_routes.dart';
import 'package:passenger_app/src/features/chat/presentation/passenger_chat_page.dart';
import 'package:passenger_app/src/features/active_ride/domain/repositories/i_track_repository.dart';
import 'package:design_system/design_system.dart';

class ChatModule {
  ChatModule._();

  static void binds(Injector i) {
    i.addLazySingleton<ChatRepositoryFactory>(
      (i) => DefaultChatRepositoryFactory(
        clientDio: i.get<Dio>(),
        tokenProvider: i.get<SecureSessionService>().readToken,
      ),
    );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ChatRoutes.driverChat,
      ChatRoutes.driverChatPath,
      child: (context, GoRouterState state) {
        final extra = SafeRouteExtra.asMap(state.extra);
        final roomId = _asNonEmptyString(extra['roomId']);
        final userId = _asNonEmptyString(extra['userId']);
        if (roomId == null || userId == null) {
          return const _ChatUnavailablePage();
        }
        return PassengerChatPage(
          roomId: roomId,
          userId: userId,
          peerId: _asNonEmptyString(extra['peerId']),
          token: _asNonEmptyString(extra['token']),
          peerName: _asNonEmptyString(extra['peerName']),
          trackRepository: Modular.get<ITrackRepository>(),
          chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

String? _asNonEmptyString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

class _ChatUnavailablePage extends StatelessWidget {
  const _ChatUnavailablePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This conversation is unavailable. Return to the trip and try again.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
