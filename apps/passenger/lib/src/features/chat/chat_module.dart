import 'package:chat/chat.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/core/config/env_config.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';

class ChatModule._() {
  static void binds(Injector i) {
    i.addLazySingleton<ChatRepositoryFactory>(
      (i) => DefaultChatRepositoryFactory(
        httpClient: i.get<Dio>(),
        tokenProvider: i.get<RefreshableTokenProvider>().getToken,
        refreshTokenProvider: i
            .get<RefreshableTokenProvider>()
            .refreshAccessToken,
        networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
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
        return ChatPage(
          roomId: roomId,
          userId: userId,
          peerId: _asNonEmptyString(extra['peerId']),
          token: _asNonEmptyString(extra['token']),
          peerName: _asNonEmptyString(extra['peerName']),
          chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
          chatUriBuilder: (id) => EnvConfig.webSocketBaseUri.replace(
            path: '/api/v1/chat/ws',
            queryParameters: {'roomId': id},
          ),
          config: ChatPageConfig.passenger,
          onBack: () => context.pop(),
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

class const _ChatUnavailablePage() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            'This conversation is unavailable. Return to the trip and try again.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
