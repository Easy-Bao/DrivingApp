import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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

            _buildSectionHeader('ACCOUNT'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSettingsRow(
                icon: LucideIcons.user,
                title: 'Account Information',
                subtitle: 'Personal details and credentials',
                onTap: () {
                  CustomToast.show(
                    context,
                    'Account info settings coming soon.',
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: LucideIcons.bell,
                title: 'Push Notifications',
                subtitle: 'Manage alert preferences',
                onTap: () {
                  CustomToast.show(
                    context,
                    'Notification settings coming soon.',
                  );
                },
              ),
            ]),

            const SizedBox(height: 28),

            _buildSectionHeader('PREFERENCES'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSettingsRow(
                icon: LucideIcons.palette,
                title: 'Theme Mode',
                subtitle: 'System default / Light / Dark',
                onTap: () {
                  CustomToast.show(context, 'Theme selection coming soon.');
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: LucideIcons.languages,
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () {
                  CustomToast.show(context, 'Language options coming soon.');
                },
              ),
            ]),

            const SizedBox(height: 28),

            _buildSectionHeader('PRIVACY & SUPPORT'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSettingsRow(
                icon: LucideIcons.shield_check,
                title: 'Privacy Center',
                subtitle: 'Manage your data and permissions',
                onTap: () {
                  CustomToast.show(context, 'Privacy controls coming soon.');
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: LucideIcons.file_text,
                title: 'Terms of Service',
                subtitle: 'Read agreements and user rights',
                onTap: () {
                  CustomToast.show(context, 'Terms agreement coming soon.');
                },
              ),
            ]),
            const SizedBox(height: 36),
          ],
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
