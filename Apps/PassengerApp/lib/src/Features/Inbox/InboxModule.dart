import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Inbox/InboxRoutes.dart';
import 'package:passenger_app/src/Features/Inbox/Presentation/Screens/InboxScreen.dart';
import 'package:shared_ui/SharedUi.dart';

class InboxModule {
  InboxModule._();

  static List<ModularRoute> routes = [];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: InboxRoutes.inbox,
      'inbox',
      child: (context, GoRouterState state) => const InboxScreen(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}
