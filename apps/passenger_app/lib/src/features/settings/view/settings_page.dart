import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback? onAppearanceTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onTermsTap;
  final VoidCallback? onAboutTap;

  const SettingsPage({
    super.key,
    this.onAppearanceTap,
    this.onLocationTap,
    this.onHelpCenterTap,
    this.onTermsTap,
    this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrow_left),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            children: [
              Text(
                'App preferences',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Control how BaoRide looks and behaves on this phone.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              const _SettingsSectionLabel('Appearance and device'),
              const SizedBox(height: 10),
              _SettingsGroup(
                children: [
                  _SettingsNavigationTile(
                    icon: LucideIcons.palette,
                    title: 'Appearance',
                    subtitle: _themeModeLabel(
                      context.watch<ThemeModeCubit>().state,
                    ),
                    onTap:
                        onAppearanceTap ??
                        () => context.pushNamed(SettingsRoutes.appearance),
                  ),
                  const Divider(),
                  BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
                    builder: (context, state) => _SettingsNavigationTile(
                      icon: LucideIcons.map_pin,
                      title: 'Location access',
                      subtitle: _locationStatusLabel(state),
                      onTap:
                          onLocationTap ??
                          () =>
                              context.pushNamed(SettingsRoutes.locationAccess),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SettingsSectionLabel('Support'),
              const SizedBox(height: 10),
              _SettingsGroup(
                children: [
                  _SettingsNavigationTile(
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
              const _SettingsSectionLabel('Legal and app information'),
              const SizedBox(height: 10),
              _SettingsGroup(
                children: [
                  _SettingsNavigationTile(
                    icon: LucideIcons.file_text,
                    title: 'Terms of Service',
                    subtitle: 'Read the rules for using BaoRide',
                    onTap:
                        onTermsTap ??
                        () => context.pushNamed(SettingsRoutes.terms),
                  ),
                  const Divider(),
                  _SettingsNavigationTile(
                    icon: LucideIcons.info,
                    title: 'About BaoRide',
                    subtitle: 'Version and open-source licenses',
                    onTap:
                        onAboutTap ??
                        () => context.pushNamed(SettingsRoutes.about),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
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

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsNavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsNavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 19,
                  color: context.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                LucideIcons.chevron_right,
                size: 19,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String text;

  const _SettingsSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
