import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/Features/Chat/ChatRoutes.dart';
import 'package:driver_app/src/Features/Chat/Presentation/Screens/DriverChatScreen.dart';
import 'package:shared_ui/SharedUi.dart';

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
