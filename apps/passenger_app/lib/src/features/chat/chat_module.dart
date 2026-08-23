import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/chat/chat_routes.dart';
import 'package:passenger_app/src/features/chat/view/driver_chat_page.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class ChatModule {
  ChatModule._();

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
        return DriverChatPage(
          roomId: roomId,
          userId: userId,
          peerId: _asNonEmptyString(extra['peerId']),
          token: _asNonEmptyString(extra['token']),
          peerName: _asNonEmptyString(extra['peerName']),
          trackRepository: Modular.get<ITrackRepository>(),
          chatRepositoryFactory: Modular.get<IChatRepositoryFactory>(),
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
