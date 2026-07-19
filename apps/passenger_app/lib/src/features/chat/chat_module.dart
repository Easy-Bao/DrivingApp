import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/chat/chat_routes.dart';
import 'package:passenger_app/src/features/chat/presentation/screens/driver_chat_screen.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

class ChatModule {
  ChatModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ChatRoutes.driverChat,
      'activity/driver-chat',
      child: (context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DriverChatScreen(
          roomId: extra?['roomId'] as String?,
          userId: extra?['userId'] as String?,
          token: extra?['token'] as String?,
          peerName: extra?['peerName'] as String?,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}
