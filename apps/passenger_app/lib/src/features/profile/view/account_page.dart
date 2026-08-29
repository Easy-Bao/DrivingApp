import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/features/profile/view/widgets/profile_avatar_widget.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class AccountPage extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const AccountPage({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.canvasColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360
                    ? 20.0
                    : 24.0;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    MediaQuery.paddingOf(context).bottom + 98,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 27,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _buildProfileSummary(context, state),
                      const SizedBox(height: 38),
                      _buildSectionTitle(context, 'Places'),
                      const SizedBox(height: 12),
                      _buildMenuGroup(context, [
                        _AccountMenuItem(
                          title: 'Saved Places',
                          subtitle: 'Home, work, and favorite destinations',
                          onTap: () => context.pushNamed(ProfileRoutes.help),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, 'Support'),
                      const SizedBox(height: 12),
                      _buildMenuGroup(context, [
                        _AccountMenuItem(
                          title: 'Help Center',
                          subtitle: 'Get help with rides and payments',
                          onTap: () =>
                              context.pushNamed(ProfileRoutes.helpCenter),
                        ),
                        _AccountMenuItem(
                          title: 'Settings',
                          subtitle: 'Appearance and app behavior',
                          onTap: () =>
                              context.pushNamed(SettingsRoutes.settings),
                        ),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSummary(BuildContext context, ProfileState state) {
    final displayName = state.name.isEmpty ? 'Passenger' : state.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('passenger-profile-summary'),
        onTap: () => _openProfileInfo(context),
        borderRadius: BorderRadius.circular(24),
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
      ),
    );
  }

  Future<void> _pushProfileInfo(BuildContext context) async {
    await context.pushNamed(ProfileRoutes.profileInfo);
    if (!context.mounted) return;
    unawaited(BlocProvider.of<ProfileCubit>(context).loadProfile());
  }

  void _openProfileInfo(BuildContext context) {
    final onProfileTap = this.onProfileTap;
    if (onProfileTap != null) {
      onProfileTap();
      return;
    }
    unawaited(_pushProfileInfo(context));
  }

  Widget _buildMenuGroup(BuildContext context, List<_AccountMenuItem> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _buildMenuTile(context, items[index]),
          if (index != items.length - 1)
            Divider(
              height: 1,
              indent: 2,
              endIndent: 2,
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
        ],
      ],
    );
  }

  Widget _buildMenuTile(BuildContext context, _AccountMenuItem item) {
    return InkWell(
      key: ValueKey<String>('passenger-account-item-${item.title}'),
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 17),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              LucideIcons.chevron_right,
              color: context.colorScheme.onSurfaceVariant,
              size: 23,
            ),
          ],
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

class _AccountMenuItem {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
