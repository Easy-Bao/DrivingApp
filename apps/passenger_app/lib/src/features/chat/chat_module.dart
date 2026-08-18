import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/chat/chat_routes.dart';
import 'package:passenger_app/src/features/chat/view/driver_chat_page.dart';
import 'package:shared_ui/shared_ui.dart';

class ChatModule {
  ChatModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ChatRoutes.driverChat,
      ChatRoutes.driverChatPath,
      child: (context, GoRouterState state) {
        final extra = SafeRouteExtra.asMap(state.extra);
        return DriverChatPage(
          roomId: extra['roomId'] as String?,
          userId: extra['userId'] as String?,
          peerId: extra['peerId'] as String?,
          token: extra['token'] as String?,
          peerName: extra['peerName'] as String?,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}
