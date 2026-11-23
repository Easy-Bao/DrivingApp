import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:passenger/src/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:passenger/src/features/profile/profile_routes.dart';
import 'package:passenger/src/features/saved_places/saved_places_routes.dart';
import 'package:passenger/src/features/settings/settings_routes.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, this.onLogout});

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
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.pageMaxWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 360
                        ? AppLayout.pagePadding
                        : AppLayout.pagePaddingWide;
                    return SingleChildScrollView(
                      key: const ValueKey<String>('passenger-account-scroll'),
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppSpacing.sm,
                        horizontalPadding,
                        AppFloatingTabBar.height + 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppPageHeader(
                            title: 'Account',
                            subtitle: 'Profile, places, and preferences',
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildProfileSummary(context, visibleState),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildHairline(context),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildSectionTitle(context, 'Account'),
                          const SizedBox(height: AppSpacing.xs),
                          _buildMenuGroup(context, [
                            _AccountMenuItem(
                              icon: LucideIcons.user_round,
                              title: 'Personal Details',
                              subtitle: 'Name, phone, email, and profile photo',
                              onTap: () => _openProfileInfo(context),
                            ),
                            _AccountMenuItem(
                              icon: LucideIcons.map_pin,
                              title: 'Saved Places',
                              subtitle: 'Home, work, and favorite destinations',
                              onTap: () =>
                                  context.pushNamed(SavedPlacesRoutes.places),
                            ),
                          ]),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildSectionTitle(context, 'Preferences'),
                          const SizedBox(height: AppSpacing.xs),
                          _buildMenuGroup(context, [
                            _AccountMenuItem(
                              icon: LucideIcons.settings,
                              title: 'Settings',
                              subtitle: 'Location, support, and app details',
                              onTap: () =>
                                  context.pushNamed(SettingsRoutes.settings),
                            ),
                          ]),
                          if (onLogout != null && isAuthenticated) ...[
                            const SizedBox(height: AppSpacing.xxxl),
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
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Padding(
      key: const ValueKey<String>('passenger-profile-summary'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          ProfileAvatar(
            initials: _getInitials(displayName),
            imagePath: state.avatarPath,
            imageData: state.avatarData,
            size: 68,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  state.phone.isEmpty ? 'Add your mobile number' : state.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.bodyMedium?.tabular.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildHairline(BuildContext context, {double indent = 0}) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
    );
  }

  Widget _buildMenuGroup(BuildContext context, List<_AccountMenuItem> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _buildMenuTile(context, items[index]),
          if (index != items.length - 1) _buildHairline(context, indent: 52),
        ],
      ],
    );
  }

  Widget _buildMenuTile(BuildContext context, _AccountMenuItem item) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Semantics(
      button: true,
      label: '${item.title}. ${item.subtitle}',
      child: InkWell(
        key: ValueKey<String>('passenger-account-item-${item.title}'),
        onTap: item.onTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.minimumTouchTarget + 18,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: textStyles.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(
                  child: Icon(
                    LucideIcons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Semantics(
      header: true,
      child: Text(
        title.toUpperCase(),
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final colorScheme = context.colorScheme;
    return SizedBox(
      key: const ValueKey<String>('passenger-account-logout'),
      height: AppSize.controlHeight,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        style:
            OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return colorScheme.error.withValues(alpha: 0.12);
                }
                return Colors.transparent;
              }),
            ),
        icon: const Icon(LucideIcons.log_out, size: 17),
        label: const Text('Log Out'),
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
