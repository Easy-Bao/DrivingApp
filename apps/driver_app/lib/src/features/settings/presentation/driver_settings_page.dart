import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/features/help_center/help_center_routes.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:driver_app/src/features/settings/settings_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverSettingsPage extends StatelessWidget {
  const DriverSettingsPage({
    super.key,
    this.onBack,
    this.onLocationTap,
    this.onHelpCenterTap,
    this.onTermsTap,
    this.onAboutTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onLocationTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onTermsTap;
  final VoidCallback? onAboutTap;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScaffold(
      onBack: onBack ?? () => context.pop(),
      children: [
        AppSettingsSection(
          label: 'Device',
          children: [
            BlocBuilder<
              DriverLocationAccessCubit,
              DriverLocationAccessViewState
            >(
              builder: (context, state) => AppSettingsNavigationTile(
                icon: LucideIcons.map_pin,
                title: 'Location access',
                subtitle: _locationStatusLabel(state),
                onTap:
                    onLocationTap ??
                    () =>
                        context.pushNamed(DriverSettingsRoutes.locationAccess),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        AppSettingsSection(
          label: 'Support',
          children: [
            AppSettingsNavigationTile(
              icon: LucideIcons.circle_question_mark,
              title: 'Help Center',
              subtitle: 'Get help with trips and earnings',
              onTap:
                  onHelpCenterTap ??
                  () => context.pushNamed(DriverHelpCenterRoutes.helpCenter),
            ),
          ],
        ),
        const SizedBox(height: 28),
        AppSettingsSection(
          label: 'Legal and app information',
          children: [
            AppSettingsNavigationTile(
              icon: LucideIcons.file_text,
              title: 'Terms of Service',
              subtitle: 'Read the rules for using BaoRide',
              onTap:
                  onTermsTap ??
                  () => context.pushNamed(DriverSettingsRoutes.terms),
            ),
            AppSettingsNavigationTile(
              icon: LucideIcons.info,
              title: 'About BaoRide',
              subtitle: 'Version and open-source licenses',
              onTap:
                  onAboutTap ??
                  () => context.pushNamed(DriverSettingsRoutes.about),
            ),
          ],
        ),
      ],
    );
  }

  static String _locationStatusLabel(DriverLocationAccessViewState state) {
    return switch (state) {
      DriverLocationAccessChecking() => 'Checking access…',
      DriverLocationAccessReady() => 'Ready to go online',
      DriverLocationAccessUnavailable(accessState: final accessState) =>
        switch (accessState) {
          LocationAccessState.ready => 'Ready to go online',
          LocationAccessState.serviceDisabled => 'Location services are off',
          LocationAccessState.denied => 'Permission is needed',
          LocationAccessState.deniedForever => 'Permission is blocked',
        },
    };
  }
}
