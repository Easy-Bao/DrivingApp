import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/chat/chat_routes.dart';
import 'package:driver_app/src/features/chat/presentation/screens/driver_chat_screen.dart';
import 'package:shared_ui/shared_ui.dart';

class ChatModule {
  ChatModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ChatRoutes.chat,
      'dashboard/driver-chat',
      child: (context, GoRouterState state) {
        final extra = SafeRouteExtra.asMap(state.extra);
        return DriverChatScreen(
          roomId: extra['roomId'] as String?,
          userId: extra['userId'] as String?,
          peerName: extra['peerName'] as String?,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}
