import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/settings/bloc/settings/settings_cubit.dart';
import 'package:passenger_app/src/features/settings/bloc/settings/settings_state.dart';
import 'package:passenger_app/src/features/settings/view/widgets/settings_item_tile_widget.dart';
import 'package:passenger_app/src/features/settings/view/widgets/settings_theme_selector_widget.dart';
import 'package:shared_ui/shared_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showThemeSelector(BuildContext context, String currentTheme) {
    final settingsCubit = BlocProvider.of<SettingsCubit>(context);
    final themeModeCubit = BlocProvider.of<ThemeModeCubit>(context);
    unawaited(
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => SettingsThemeSelectorWidget(
          selectedThemeMode: currentTheme,
          onThemeSelected: (newMode) {
            unawaited(settingsCubit.updateThemeMode(newMode));
            unawaited(
              themeModeCubit.setThemeMode(ThemeModeCodec.decode(newMode)),
            );
          },
        ),
      ),
    );
  }

  String _formatThemeSubtitle(String modeKey) {
    switch (modeKey) {
      case 'light':
        return 'Light Mode';
      case 'dark':
        return 'Dark Mode';
      case 'system':
      default:
        return 'System Default';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          style: IconButton.styleFrom(shape: const CircleBorder()),
          icon: Icon(
            LucideIcons.arrow_left,
            color: context.colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoadingState || state is SettingsInitialState) {
            return Center(
              child: CircularProgressIndicator(
                color: context.colorScheme.onSurface,
              ),
            );
          }

          final settings = (state is SettingsLoadedState)
              ? state.settings
              : null;

          final pushEnabled = settings?.pushNotificationsEnabled ?? true;
          final locationEnabled = settings?.locationSharingEnabled ?? true;
          final themeMode = settings?.preferredThemeMode ?? 'system';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Preferences',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your application experience',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),

                _buildSectionHeader(context, 'Preferences'),
                const SizedBox(height: 12),
                _buildSettingsRow(
                  context,
                  icon: LucideIcons.palette,
                  title: 'Theme Mode',
                  subtitle: _formatThemeSubtitle(themeMode),
                  onTap: () => _showThemeSelector(context, themeMode),
                ),

                const SizedBox(height: 28),

                _buildSectionHeader(context, 'NOTIFICATIONS & PRIVACY'),
                const SizedBox(height: 12),
                SettingsItemTileWidget(
                  icon: LucideIcons.bell,
                  title: 'Push Notifications',
                  subtitle: 'Receive real-time ride updates',
                  value: pushEnabled,
                  onChanged: (val) => unawaited(
                    BlocProvider.of<SettingsCubit>(
                      context,
                    ).togglePushNotifications(val),
                  ),
                ),
                SettingsItemTileWidget(
                  icon: LucideIcons.map_pin,
                  title: 'Location Sharing',
                  subtitle: 'Share live position for pickup accuracy',
                  value: locationEnabled,
                  onChanged: (val) => unawaited(
                    BlocProvider.of<SettingsCubit>(
                      context,
                    ).toggleLocationSharing(val),
                  ),
                ),

                const SizedBox(height: 28),

                _buildSectionHeader(context, 'SUPPORT & LEGAL'),
                const SizedBox(height: 12),
                _buildSettingsCard(context, [
                  _buildSettingsRow(
                    context,
                    icon: LucideIcons.shield_check,
                    title: 'Privacy Center',
                    subtitle: 'Manage your data and permissions',
                    onTap: () {
                      CustomToast.show(context, 'Privacy controls active.');
                    },
                  ),
                  _buildDivider(context),
                  _buildSettingsRow(
                    context,
                    icon: LucideIcons.file_text,
                    title: 'Terms of Service',
                    subtitle: 'Read agreements and user rights',
                    onTap: () {
                      CustomToast.show(context, 'Terms agreement active.');
                    },
                  ),
                ]),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.15,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: context.semanticColors.warmAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              color: context.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(height: 1, color: context.colorScheme.outlineVariant),
    );
  }
}
