import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:design_system/design_system.dart';

class AboutBaoRidePage extends StatelessWidget {
  const AboutBaoRidePage({super.key, this.onBack, this.onLicensesTap});

  final VoidCallback? onBack;
  final VoidCallback? onLicensesTap;

  @override
  Widget build(BuildContext context) {
    return AppAboutPage(
      applicationName: 'BaoRide Passenger',
      applicationVersion: '1.0.0',
      description:
          'BaoRide connects passengers with nearby drivers and keeps pickup, trip, and payment details in one focused experience.',
      icon: LucideIcons.car_front,
      onBack: onBack ?? () => context.pop(),
      onLicensesTap:
          onLicensesTap ?? () => context.pushNamed(SettingsRoutes.licenses),
    );
  }
}
