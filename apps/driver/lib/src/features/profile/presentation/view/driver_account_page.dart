import 'dart:async';

import 'package:driver/src/features/auth/auth_routes.dart';
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

class const AccountPage({super.key, required this.onLogout})
    extends StatefulWidget {
  final Future<void> Function() onLogout;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) => Scaffold(
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
                      ? 20.0
                      : AppLayout.pagePaddingWide;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppLayout.pagePadding,
                      horizontalPadding,
                      MediaQuery.paddingOf(context).bottom + 98,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppPageHeader(title: 'Account'),
                        const SizedBox(height: AppSpacing.xxl),
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
                              BlocProvider.of<AccountCubit>(context).load(),
                            ),
                            onDismiss: () =>
                                BlocProvider.of<AccountCubit>(context)
                                    .dismissError(),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSectionTitle(context, 'Driver Details'),
                        const SizedBox(height: 12),
                        _buildMenuGroup(context, [
                          _AccountMenuItem(
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
                          _AccountMenuItem(
                            icon: LucideIcons.file_text,
                            title: 'Documents',
                            subtitle:
                                'Manage your driver verification documents',
                            onTap: () => unawaited(
                              _openEditableDestination(
                                context,
                                ProfileRoutes.documents,
                              ),
                            ),
                          ),
                          _AccountMenuItem(
                            icon: LucideIcons.wallet_cards,
                            title: 'Performance',
                            subtitle: 'Ratings, trips, and earnings',
                            onTap: () => context.pushNamed(
                              PerformanceRoutes.performance,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'App settings'),
                        const SizedBox(height: 12),
                        _buildMenuGroup(context, [
                          _AccountMenuItem(
                            icon: LucideIcons.settings,
                            title: 'Settings',
                            subtitle: 'Location, support, and app details',
                            onTap: () =>
                                context.pushNamed(SettingsRoutes.settings),
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

  Widget _buildProfileSummary(BuildContext context, AccountSnapshot account) {
    final displayName = account.name.isEmpty ? 'Driver' : account.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('driver-profile-summary'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(displayName),
                  style: context.textStyles.titleLarge?.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.onSurface,
                      ),
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
    final accountCubit = BlocProvider.of<AccountCubit>(context);
    await context.pushNamed(routeName);
    if (context.mounted) unawaited(accountCubit.load());
  }

  String _vehicleSummary(AccountSnapshot account) {
    final vehicle = account.vehicleType.trim();
    final plate = account.plateNumber.trim();
    if (vehicle.isEmpty && plate.isEmpty) {
      return 'No registered vehicle information';
    }
    if (vehicle.isEmpty) return 'Plate number $plate';
    if (plate.isEmpty) return vehicle;
    return '$vehicle · Plate $plate';
  }

  Widget _buildMenuGroup(BuildContext context, List<_AccountMenuItem> items) {
    return AppSurfaceCard(
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
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, _AccountMenuItem item) {
    return InkWell(
      key: ValueKey<String>('driver-account-item-${item.title}'),
      onTap: item.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  size: 18,
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm / 2),
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
              const SizedBox(width: AppSpacing.sm),
              Icon(
                LucideIcons.chevron_right,
                color: context.colorScheme.onSurfaceVariant,
                size: AppSize.navigationIcon,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
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
