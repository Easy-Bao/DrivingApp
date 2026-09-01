import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/settings/presentation/view/about_bao_ride_page.dart';
import 'package:passenger/src/features/settings/presentation/view/location_access_status_page.dart';
import 'package:passenger/src/features/settings/presentation/view/settings_page.dart';
import 'package:passenger/src/features/settings/presentation/view/terms_of_service_page.dart';
import 'package:passenger/src/features/settings/settings_routes.dart';

class SettingsModule._() {
  static List<ModularRoute> routes = [
    ChildRoute(
      name: SettingsRoutes.settings,
      SettingsRoutes.settingsPath,
      child: (context, GoRouterState state) => const SettingsPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: SettingsRoutes.locationAccess,
      SettingsRoutes.locationAccessPath,
      child: (context, GoRouterState state) => const LocationAccessStatusPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: SettingsRoutes.terms,
      SettingsRoutes.termsPath,
      child: (context, GoRouterState state) => const TermsOfServicePage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: SettingsRoutes.about,
      SettingsRoutes.aboutPath,
      child: (context, GoRouterState state) => const AboutBaoRidePage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: SettingsRoutes.licenses,
      SettingsRoutes.licensesPath,
      child: (context, GoRouterState state) => const LicensePage(
        applicationName: 'BaoRide Passenger',
        applicationVersion: '1.0.0',
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}
