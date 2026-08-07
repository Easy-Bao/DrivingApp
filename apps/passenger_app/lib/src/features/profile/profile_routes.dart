import 'package:passenger_app/src/core/routing/app_routes.dart';

abstract final class ProfileRoutes {
  static const String account = 'Account';
  static const String accountPath = 'account';
  static const String fullAccountPath =
      '${AppRoutes.passengerModulePath}$accountPath';
  static const String profileInfo = 'ProfileInfo';
  static const String profileInfoPath = 'account/profile-info';
  static const String helpCenter = 'HelpCenter';
  static const String helpCenterPath = 'account/help-center';
  static const String help = 'Help';
  static const String helpPath = 'help';
  static const String fullHelpPath =
      '${AppRoutes.passengerModulePath}$helpPath';
}
