import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/inbox/inbox_routes.dart';
import 'package:passenger_app/src/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

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
