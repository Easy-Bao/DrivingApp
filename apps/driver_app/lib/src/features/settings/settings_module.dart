import 'package:driver_app/src/features/settings/settings_routes.dart';
import 'package:driver_app/src/features/settings/presentation/driver_about_bao_ride_page.dart';
import 'package:driver_app/src/features/settings/presentation/driver_location_access_status_page.dart';
import 'package:driver_app/src/features/settings/presentation/driver_settings_page.dart';
import 'package:driver_app/src/features/settings/presentation/driver_terms_of_service_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class DriverSettingsModule {
  DriverSettingsModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: DriverSettingsRoutes.settings,
      DriverSettingsRoutes.settingsPath,
      child: (context, GoRouterState state) => const DriverSettingsPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: DriverSettingsRoutes.locationAccess,
      DriverSettingsRoutes.locationAccessPath,
      child: (context, GoRouterState state) =>
          const DriverLocationAccessStatusPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: DriverSettingsRoutes.terms,
      DriverSettingsRoutes.termsPath,
      child: (context, GoRouterState state) => const DriverTermsOfServicePage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: DriverSettingsRoutes.about,
      DriverSettingsRoutes.aboutPath,
      child: (context, GoRouterState state) => const DriverAboutBaoRidePage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: DriverSettingsRoutes.licenses,
      DriverSettingsRoutes.licensesPath,
      child: (context, GoRouterState state) => const LicensePage(
        applicationName: 'BaoRide Driver',
        applicationVersion: '1.0.0',
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}
