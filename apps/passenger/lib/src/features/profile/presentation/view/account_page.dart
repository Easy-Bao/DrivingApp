import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile/profile_cubit.dart';
import 'package:passenger/src/features/profile/presentation/widgets/profile_avatar_widget.dart';
import 'package:passenger/src/features/profile/profile_routes.dart';
import 'package:passenger/src/features/saved_places/saved_places_routes.dart';
import 'package:passenger/src/features/settings/settings_routes.dart';

class const AccountPage({super.key, this.onLogout}) extends StatelessWidget {
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final isAuthenticated = context.select<SessionBloc, bool>(
          (bloc) => bloc.state.isAuthenticated,
        );
        final visibleState = isAuthenticated ? state : const ProfileState();
        return Scaffold(
          backgroundColor: context.canvasColor,
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: EasyRideDesignTokens.pageMaxWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 360
                        ? 20.0
                        : EasyRideDesignTokens.pageHorizontalPaddingWide;
                    return SingleChildScrollView(
                      key: const ValueKey<String>('passenger-account-scroll'),
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        EasyRideDesignTokens.pageTopPadding,
                        horizontalPadding,
                        AppFloatingTabBar.height + 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EasyRidePageHeader(title: 'Account'),
                          const SizedBox(
                            height: EasyRideDesignTokens.sectionGap,
                          ),
                          _buildProfileSummary(context, visibleState),
                          const SizedBox(height: 28),
                          _buildSectionTitle(context, 'Personal information'),
                          const SizedBox(height: 12),
                          _buildMenuGroup(context, [
                            _AccountMenuItem(
                              icon: LucideIcons.user_round,
                              title: 'Personal Details',
                              subtitle: 'Name, phone, email, and profile photo',
                              onTap: () => _openProfileInfo(context),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, 'Places'),
                          const SizedBox(height: 12),
                          _buildMenuGroup(context, [
                            _AccountMenuItem(
                              icon: LucideIcons.map_pin,
                              title: 'Saved Places',
                              subtitle: 'Home, work, and favorite destinations',
                              onTap: () =>
                                  context.pushNamed(SavedPlacesRoutes.places),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, 'Support'),
                          const SizedBox(height: 12),
                          _buildMenuGroup(context, [
                            _AccountMenuItem(
                              icon: LucideIcons.circle_question_mark,
                              title: 'Help Center',
                              subtitle: 'Get help with rides and payments',
                              onTap: () =>
                                  context.pushNamed(ProfileRoutes.helpCenter),
                            ),
                            _AccountMenuItem(
                              icon: LucideIcons.settings,
                              title: 'Settings',
                              subtitle: 'Location access and app support',
                              onTap: () =>
                                  context.pushNamed(SettingsRoutes.settings),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            context,
                            'Legal and app information',
                          ),
                          const SizedBox(height: 12),
                          _buildMenuGroup(context, [
                            _AccountMenuItem(
                              icon: LucideIcons.file_text,
                              title: 'Terms of Service',
                              subtitle: 'Read the rules for using EasyRide',
                              onTap: () =>
                                  context.pushNamed(SettingsRoutes.terms),
                            ),
                            _AccountMenuItem(
                              icon: LucideIcons.info,
                              title: 'About EasyRide',
                              subtitle: 'Version and open-source licenses',
                              onTap: () =>
                                  context.pushNamed(SettingsRoutes.about),
                            ),
                          ]),
                          if (onLogout != null && isAuthenticated) ...[
                            const SizedBox(height: 24),
                            _buildLogoutButton(context),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSummary(BuildContext context, ProfileState state) {
    final displayName = state.name.isEmpty ? 'Passenger' : state.name;

    return Material(
      key: const ValueKey<String>('passenger-profile-summary'),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ProfileAvatarWidget(
              initials: _getInitials(displayName),
              imagePath: state.avatarPath,
              imageData: state.avatarData,
              size: 76,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    state.phone.isEmpty
                        ? 'Add your mobile number'
                        : state.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pushProfileInfo(BuildContext context) async {
    await context.pushNamed(ProfileRoutes.profileInfo);
    if (!context.mounted) return;
    unawaited(BlocProvider.of<ProfileCubit>(context).loadProfile());
  }

  void _openProfileInfo(BuildContext context) {
    unawaited(_pushProfileInfo(context));
  }

  Widget _buildMenuGroup(BuildContext context, List<_AccountMenuItem> items) {
    return EasyRideSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _buildMenuTile(context, items[index]),
            if (index != items.length - 1)
              Divider(
                height: 1,
                indent: 2,
                endIndent: 2,
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.65,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, _AccountMenuItem item) {
    return InkWell(
      key: ValueKey<String>('passenger-account-item-${item.title}'),
      onTap: item.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: EasyRideDesignTokens.minimumTouchTarget + 28,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EasyRideDesignTokens.cardPadding,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  size: 18,
                  color: context.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: EasyRideDesignTokens.cardPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: context.textStyles.titleMedium),
                    const SizedBox(height: EasyRideDesignTokens.compactGap / 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: EasyRideDesignTokens.compactGap),
              Icon(
                LucideIcons.chevron_right,
                color: context.colorScheme.onSurfaceVariant,
                size: EasyRideDesignTokens.navigationIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: context.colorScheme.onSurfaceVariant,
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('passenger-account-logout'),
      height: 58,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colorScheme.error,
          side: BorderSide(
            color: context.colorScheme.error.withValues(alpha: 0.35),
          ),
          backgroundColor: context.colorScheme.error.withValues(alpha: 0.04),
          shape: const StadiumBorder(),
        ),
        child: const Text('Log Out'),
      ),
    );
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'P';
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

class const _AccountMenuItem({
  required this.icon,
  required this.title,
  required this.subtitle,
  required this.onTap,
}) {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
