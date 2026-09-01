import 'package:passenger/src/app/navigation/app_routes.dart';

abstract final class InboxRoutes {
  static const String inbox = 'Inbox';
  static const String inboxPath = 'inbox';
  static const String fullInboxPath =
      '${AppRoutes.passengerModulePath}$inboxPath';
}
