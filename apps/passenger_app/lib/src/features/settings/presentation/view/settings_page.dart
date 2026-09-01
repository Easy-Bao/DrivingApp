import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger_app/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/presentation/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:design_system/design_system.dart';

class const SettingsPage({
  super.key,
  this.onLocationTap,
  this.onHelpCenterTap,
  this.onTermsTap,
  this.onAboutTap,
}) extends StatelessWidget {
  final VoidCallback? onLocationTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onTermsTap;
  final VoidCallback? onAboutTap;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScaffold(
      onBack: () => context.pop(),
      children: [
        AppSettingsSection(
          label: 'Device',
          children: [
            BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
              builder: (context, state) => AppSettingsNavigationTile(
                icon: LucideIcons.map_pin,
                title: 'Location access',
                subtitle: _locationStatusLabel(state),
                onTap:
                    onLocationTap ??
                    () => context.pushNamed(SettingsRoutes.locationAccess),
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
              subtitle: 'Get help with rides and payments',
              onTap:
                  onHelpCenterTap ??
                  () => context.pushNamed(ProfileRoutes.helpCenter),
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
                  onTermsTap ?? () => context.pushNamed(SettingsRoutes.terms),
            ),
            AppSettingsNavigationTile(
              icon: LucideIcons.info,
              title: 'About BaoRide',
              subtitle: 'Version and open-source licenses',
              onTap:
                  onAboutTap ?? () => context.pushNamed(SettingsRoutes.about),
            ),
          ],
        ),
      ],
    );
  }

  static String _locationStatusLabel(LocationAccessViewState state) {
    return switch (state) {
      LocationAccessChecking() => 'Checking access…',
      LocationAccessReady() => 'Ready for pickups',
      LocationAccessUnavailable(accessState: final accessState) =>
        switch (accessState) {
          LocationAccessState.ready => 'Ready for pickups',
          LocationAccessState.serviceDisabled => 'Location services are off',
          LocationAccessState.denied => 'Permission is needed',
          LocationAccessState.deniedForever => 'Permission is blocked',
        },
    };
  }
}
