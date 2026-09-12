import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver/src/features/settings/settings_routes.dart';
import 'package:design_system/design_system.dart';

class const DriverAboutEasyRidePage({super.key, this.onBack, this.onLicensesTap})
    extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLicensesTap;

  @override
  Widget build(BuildContext context) {
    return AppAboutPage(
      applicationName: 'EasyRide Driver',
      applicationVersion: '1.0.0',
      description: 'EasyRide gives drivers one place to manage availability, trips, earnings, vehicle details, and rider pickups.',
      icon: LucideIcons.car_front,
      onBack: onBack ?? () => context.pop(),
      onLicensesTap:
          onLicensesTap ??
          () => context.pushNamed(DriverSettingsRoutes.licenses),
    );
  }
}
