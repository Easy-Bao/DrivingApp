import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (_, current) =>
          current is GuestSession || current is SessionFailure,
      listener: _handleSessionState,
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final initials = _getInitials(state.name);

          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 650;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      compact ? 4 : 10,
                      20,
                      MediaQuery.paddingOf(context).bottom + 76,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        _buildProfileSummary(context, state, initials),
                        SizedBox(height: compact ? 16 : 22),
                        _buildSectionTitle('Places and Safety'),
                        const SizedBox(height: 7),
                        _buildMenuGroup([
                          _AccountMenuItem(
                            icon: LucideIcons.map_pin,
                            title: 'Saved Places',
                            subtitle: 'Home, work, and favorite destinations',
                            onTap: () => context.pushNamed(ProfileRoutes.help),
                          ),
                          _AccountMenuItem(
                            icon: LucideIcons.shield,
                            title: 'Safety Center',
                            subtitle: 'Ride safety tools and guidance',
                            onTap: () => CustomToast.show(
                              context,
                              'Safety Center is coming soon.',
                            ),
                          ),
                        ], compact: compact),
                        SizedBox(height: compact ? 14 : 20),
                        _buildSectionTitle('Support'),
                        const SizedBox(height: 7),
                        _buildMenuGroup([
                          _AccountMenuItem(
                            icon: LucideIcons.message_circle_question_mark,
                            title: 'Help Center',
                            subtitle: 'Get help with rides and payments',
                            onTap: () =>
                                context.pushNamed(ProfileRoutes.helpCenter),
                          ),
                          _AccountMenuItem(
                            icon: LucideIcons.settings,
                            title: 'Settings',
                            subtitle: 'Notifications and app preferences',
                            onTap: () =>
                                context.pushNamed(SettingsRoutes.settings),
                          ),
                        ], compact: compact),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _isLoggingOut
                              ? null
                              : () => _handleLogout(context),
                          icon: _isLoggingOut
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.cancel,
                                  ),
                                )
                              : const Icon(LucideIcons.log_out, size: 17),
                          label: Text(
                            _isLoggingOut ? 'Logging Out…' : 'Log Out',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.cancel,
                            side: BorderSide(
                              color: AppTheme.cancel.withValues(alpha: 0.24),
                            ),
                            backgroundColor: AppTheme.cancel.withValues(
                              alpha: 0.05,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSummary(
    BuildContext context,
    ProfileState state,
    String initials,
  ) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppTheme.secondaryColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.name.isNotEmpty ? state.name : 'Passenger',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                state.phone.isNotEmpty ? state.phone : 'No Phone Number',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.tertiaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit Profile',
          icon: const Icon(
            LucideIcons.pencil,
            color: AppTheme.primaryColor,
            size: 18,
          ),
          onPressed: () async {
            await context.pushNamed(ProfileRoutes.profileInfo);
            if (!context.mounted) return;
            unawaited(BlocProvider.of<ProfileCubit>(context).loadProfile());
          },
        ),
      ],
    );
  }

  Widget _buildMenuGroup(
    List<_AccountMenuItem> items, {
    required bool compact,
  }) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _buildMenuTile(items[index], compact: compact),
              if (index != items.length - 1)
                const Divider(height: 1, indent: 48, endIndent: 12),
            ],
          ],
        ),
      ),
    );
  }

  void _handleSessionState(BuildContext context, SessionState state) {
    switch (state) {
      case GuestSession():
        context.goNamed(AuthRoutes.signin);
      case SessionFailure():
        if (_isLoggingOut) {
          setState(() => _isLoggingOut = false);
          CustomToast.show(
            context,
            'Unable to log out. Please try again.',
            isError: true,
          );
        }
      case SessionLoading() || AuthenticatedSession():
        break;
    }
  }

  Widget _buildMenuTile(_AccountMenuItem item, {required bool compact}) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          children: [
            Icon(item.icon, color: AppTheme.primaryColor, size: 17),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.tertiaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _handleLogout(BuildContext context) {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    BlocProvider.of<SessionBloc>(context).add(const SessionLogoutRequested());
  }
}

class _AccountMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
