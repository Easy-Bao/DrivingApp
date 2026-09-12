import 'dart:async';

import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/help_center/help_center_routes.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver/src/features/profile/profile_routes.dart';
import 'package:driver/src/features/performance/performance_routes.dart';
import 'package:driver/src/features/settings/settings_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class const DriverAccountPage({super.key, required this.onLogout})
    extends StatefulWidget {
  final Future<void> Function() onLogout;

  @override
  State<DriverAccountPage> createState() => _DriverAccountPageState();
}

class _DriverAccountPageState extends State<DriverAccountPage> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverAccountCubit, DriverAccountState>(
      builder: (context, state) => Scaffold(
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
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      EasyRideDesignTokens.pageTopPadding,
                      horizontalPadding,
                      MediaQuery.paddingOf(context).bottom + 98,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const EasyRidePageHeader(title: 'Account'),
                        const SizedBox(height: EasyRideDesignTokens.sectionGap),
                        _buildProfileSummary(context, state.account),
                        if (state.isLoading) ...[
                          const SizedBox(height: 20),
                          const LinearProgressIndicator(),
                        ],
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 20),
                          AppErrorBanner(
                            message: state.errorMessage!,
                            onRetry: () => unawaited(
                              BlocProvider.of<DriverAccountCubit>(context)
                                  .load(),
                            ),
                          ),
                        ],
                        const SizedBox(height: EasyRideDesignTokens.sectionGap),
                        _buildSectionTitle(context, 'Driver Details'),
                        const SizedBox(height: 12),
                        _buildMenuGroup(context, [
                          _DriverAccountMenuItem(
                            icon: LucideIcons.car_front,
                            title: 'Vehicle Information',
                            subtitle: _vehicleSummary(state.account),
                            onTap: () => unawaited(
                              _openEditableDestination(
                                context,
                                ProfileRoutes.vehicleInformation,
                              ),
                            ),
                          ),
                          _DriverAccountMenuItem(
                            icon: LucideIcons.wallet_cards,
                            title: 'Performance',
                            subtitle: 'Ratings, trips, and earnings',
                            onTap: () => context.pushNamed(
                              PerformanceRoutes.performance,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'Support'),
                        const SizedBox(height: 12),
                        _buildMenuGroup(context, [
                          _DriverAccountMenuItem(
                            icon: LucideIcons.settings,
                            title: 'Settings',
                            subtitle: 'Location access and app support',
                            onTap: () => context.pushNamed(
                              DriverSettingsRoutes.settings,
                            ),
                          ),
                          _DriverAccountMenuItem(
                            icon: LucideIcons.circle_question_mark,
                            title: 'Help Center',
                            subtitle: 'Support and frequently asked questions',
                            onTap: () => context.pushNamed(
                              DriverHelpCenterRoutes.helpCenter,
                            ),
                          ),
                          _DriverAccountMenuItem(
                            icon: LucideIcons.info,
                            title: 'About EasyRide',
                            subtitle: 'Driver app version and licenses',
                            onTap: () =>
                                context.pushNamed(DriverSettingsRoutes.about),
                          ),
                        ]),
                        const SizedBox(height: 32),
                        _buildLogoutButton(context),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummary(
    BuildContext context,
    DriverAccountSnapshot account,
  ) {
    final displayName = account.name.isEmpty ? 'Driver' : account.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('driver-profile-summary'),
        borderRadius: BorderRadius.circular(EasyRideDesignTokens.cardRadius),
        onTap: () => unawaited(
          _openEditableDestination(context, ProfileRoutes.personalDetails),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                key: const ValueKey<String>('driver-profile-avatar'),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: context.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(displayName),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colorScheme.onSecondaryContainer,
                  ),
                ),
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      account.phone.isEmpty
                          ? 'Add your mobile number'
                          : account.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Personal Details',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                size: 21,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditableDestination(
    BuildContext context,
    String routeName,
  ) async {
    final accountCubit = BlocProvider.of<DriverAccountCubit>(context);
    await context.pushNamed(routeName);
    if (context.mounted) unawaited(accountCubit.load());
  }

  String _vehicleSummary(DriverAccountSnapshot account) {
    final vehicle = account.vehicleType.trim();
    final plate = account.plateNumber.trim();
    if (vehicle.isEmpty && plate.isEmpty) {
      return 'No registered vehicle information';
    }
    if (vehicle.isEmpty) return 'Plate number $plate';
    if (plate.isEmpty) return vehicle;
    return '$vehicle · Plate $plate';
  }

  Widget _buildMenuGroup(
    BuildContext context,
    List<_DriverAccountMenuItem> items,
  ) {
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: context.colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildMenuTile(BuildContext context, _DriverAccountMenuItem item) {
    return InkWell(
      key: ValueKey<String>('driver-account-item-${item.title}'),
      onTap: item.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: EasyRideDesignTokens.compactGap / 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
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

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('driver-account-logout'),
      height: 58,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoggingOut ? null : () => _handleLogout(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colorScheme.error,
          side: BorderSide(
            color: context.colorScheme.error.withValues(alpha: 0.35),
          ),
          backgroundColor: context.colorScheme.error.withValues(alpha: 0.04),
          shape: const StadiumBorder(),
        ),
        child: _isLoggingOut
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: context.colorScheme.error,
                ),
              )
            : const Text('Log Out'),
      ),
    );
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'D';
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await widget.onLogout();
      if (context.mounted) context.goNamed(AuthRoutes.signin);
    } catch (error) {
      debugPrint('Unable to log out driver: $error');
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
    }
  }
}

class const _DriverAccountMenuItem({
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
