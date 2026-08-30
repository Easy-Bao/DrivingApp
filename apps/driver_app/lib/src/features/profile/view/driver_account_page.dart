import 'dart:async';

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/help_center/help_center_routes.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/settings/settings_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverAccountPage extends StatefulWidget {
  const DriverAccountPage({super.key});

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
              constraints: const BoxConstraints(maxWidth: 600),
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
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 26),
                        _buildProfileSummary(context, state.account),
                        if (state.isLoading) ...[
                          const SizedBox(height: 20),
                          const LinearProgressIndicator(),
                        ],
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 20),
                          _AccountRefreshNotice(
                            message: state.errorMessage!,
                            onRetry: () => unawaited(
                              BlocProvider.of<DriverAccountCubit>(
                                context,
                              ).load(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 38),
                        _buildSectionTitle(context, 'Driver Details'),
                        const SizedBox(height: 12),
                        _buildMenuGroup(context, [
                          _DriverAccountMenuItem(
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
                            title: 'Performance',
                            subtitle: 'Ratings, trips, and earnings',
                            onTap: () =>
                                context.pushNamed(ProfileRoutes.performance),
                          ),
                        ]),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'Support'),
                        const SizedBox(height: 12),
                        _buildMenuGroup(context, [
                          _DriverAccountMenuItem(
                            title: 'Settings',
                            subtitle: 'Appearance and app behavior',
                            onTap: () => context.pushNamed(
                              DriverSettingsRoutes.settings,
                            ),
                          ),
                          _DriverAccountMenuItem(
                            title: 'Help Center',
                            subtitle: 'Support and frequently asked questions',
                            onTap: () => context.pushNamed(
                              DriverHelpCenterRoutes.helpCenter,
                            ),
                          ),
                          _DriverAccountMenuItem(
                            title: 'About BaoRide',
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
        borderRadius: BorderRadius.circular(24),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.primary,
                      ),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, _DriverAccountMenuItem item) {
    return InkWell(
      key: ValueKey<String>('driver-account-item-${item.title}'),
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
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
              const SizedBox(width: 14),
              Icon(
                LucideIcons.chevron_right,
                color: context.colorScheme.onSurfaceVariant,
                size: 21,
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
      final position = LocationService.lastPosition;
      try {
        await Modular.get<DashboardCubit>().forceOffline(
          lat: position?.latitude ?? 0,
          lng: position?.longitude ?? 0,
        );
      } catch (error) {
        debugPrint('Unable to clear driver availability during logout: $error');
      }
      try {
        await Modular.get<BackgroundTelemetryService>().stop();
      } catch (error) {
        debugPrint('Unable to stop driver telemetry during logout: $error');
      }
      await Modular.get<SecureSessionService>().clearSession();
      if (context.mounted) context.goNamed(AuthRoutes.signin);
    } catch (error) {
      debugPrint('Unable to log out driver: $error');
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
    }
  }
}

class _AccountRefreshNotice extends StatelessWidget {
  const _AccountRefreshNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circle_alert,
            size: 20,
            color: context.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DriverAccountMenuItem {
  const _DriverAccountMenuItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
