import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:passenger_app/src/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:passenger_app/src/features/settings/presentation/bloc/settings_state.dart';
import 'package:passenger_app/src/features/settings/presentation/widgets/settings_item_tile_widget.dart';
import 'package:passenger_app/src/features/settings/presentation/widgets/settings_theme_selector_widget.dart';
import 'package:shared_ui/shared_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsCubit _settingsCubit;

  @override
  void initState() {
    super.initState();
    _settingsCubit = SettingsCubit(
      settingsRepository: SettingsRepositoryImpl(),
    );
    unawaited(_settingsCubit.loadSettings());
  }

  @override
  void dispose() {
    unawaited(_settingsCubit.close());
    super.dispose();
  }

  void _showThemeSelector(BuildContext context, String currentTheme) {
    unawaited(
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => SettingsThemeSelectorWidget(
          selectedThemeMode: currentTheme,
          onThemeSelected: (newMode) {
            unawaited(_settingsCubit.updateThemeMode(newMode));
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
    return BlocProvider<SettingsCubit>.value(
      value: _settingsCubit,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrow_left,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Settings',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoadingState ||
                state is SettingsInitialState) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
                  const Text(
                    'App Preferences',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your application experience',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildSectionHeader('PREFERENCES'),
                  const SizedBox(height: 12),
                  _buildSettingsRow(
                    icon: LucideIcons.palette,
                    title: 'Theme Mode',
                    subtitle: _formatThemeSubtitle(themeMode),
                    onTap: () => _showThemeSelector(context, themeMode),
                  ),

                  const SizedBox(height: 28),

                  _buildSectionHeader('NOTIFICATIONS & PRIVACY'),
                  const SizedBox(height: 12),
                  SettingsItemTileWidget(
                    icon: LucideIcons.bell,
                    title: 'Push Notifications',
                    subtitle: 'Receive real-time ride updates',
                    value: pushEnabled,
                    onChanged: (val) =>
                        unawaited(_settingsCubit.togglePushNotifications(val)),
                  ),
                  SettingsItemTileWidget(
                    icon: LucideIcons.map_pin,
                    title: 'Location Sharing',
                    subtitle: 'Share live position for pickup accuracy',
                    value: locationEnabled,
                    onChanged: (val) =>
                        unawaited(_settingsCubit.toggleLocationSharing(val)),
                  ),

                  const SizedBox(height: 28),

                  _buildSectionHeader('SUPPORT & LEGAL'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSettingsRow(
                      icon: LucideIcons.shield_check,
                      title: 'Privacy Center',
                      subtitle: 'Manage your data and permissions',
                      onTap: () {
                        CustomToast.show(context, 'Privacy controls active.');
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsRow(
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutralColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderSide.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsRow({
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
              decoration: const BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF8A4F35), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(height: 1, color: AppTheme.borderSide),
    );
  }
}
