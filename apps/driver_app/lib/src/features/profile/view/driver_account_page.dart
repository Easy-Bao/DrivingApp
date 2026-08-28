import 'dart:async';

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';

class DriverAccountPage extends StatefulWidget {
  const DriverAccountPage({super.key});

  @override
  State<DriverAccountPage> createState() => _DriverAccountPageState();
}

class _DriverAccountPageState extends State<DriverAccountPage> {
  String _name = '';
  String _phone = '';
  String _vehicleType = '';
  String _plateNumber = '';
  String _rating = '—';

  int _totalTrips = 0;
  int _completedTrips = 0;
  double _lifetimeEarnings = 0;
  double _averageRating = 0;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _applyAccount(BlocProvider.of<DriverAccountCubit>(context).state.account);
  }

  void _applyAccount(DriverAccountSnapshot account) {
    _name = account.name;
    _phone = account.phone;
    _vehicleType = account.vehicleType;
    _plateNumber = account.plateNumber;
    _rating = account.ratingLabel;
    _totalTrips = account.totalTrips;
    _completedTrips = account.completedTrips;
    _lifetimeEarnings = account.lifetimeEarnings;
    _averageRating = account.averageRating;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverAccountCubit, DriverAccountState>(
      listenWhen: (previous, current) => previous.account != current.account,
      listener: (_, state) {
        if (mounted) setState(() => _applyAccount(state.account));
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
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
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _buildProfileSummary(context),
                    const SizedBox(height: 38),
                    _buildSectionTitle('Driver Details'),
                    const SizedBox(height: 12),
                    _buildMenuGroup([
                      _DriverAccountMenuItem(
                        title: 'Vehicle Information',
                        subtitle: _vehicleSummary,
                        onTap: () => _showVehicleDetails(context),
                      ),
                      _DriverAccountMenuItem(
                        title: 'Performance',
                        subtitle: _performanceSummary,
                        onTap: () => _showPerformanceDetails(context),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Support'),
                    const SizedBox(height: 12),
                    _buildMenuGroup([
                      _DriverAccountMenuItem(
                        title: 'Help Center',
                        subtitle: 'Support and frequently asked questions',
                        onTap: () => _showHelpCenter(context),
                      ),
                      _DriverAccountMenuItem(
                        title: 'About BaoRide',
                        subtitle: 'Driver app version 1.0.0',
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'BaoRide Driver',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(
                            LucideIcons.car_front,
                            color: AppTheme.primaryColor,
                          ),
                        ),
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
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    final displayName = _name.isEmpty ? 'Driver' : _name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('driver-profile-summary'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => unawaited(_openProfileInfo(context)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                key: const ValueKey<String>('driver-profile-avatar'),
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(displayName),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
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
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _phone.isEmpty ? 'Add your mobile number' : _phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.tertiaryColor,
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

  Future<void> _openProfileInfo(BuildContext context) async {
    final accountCubit = BlocProvider.of<DriverAccountCubit>(context);
    await context.pushNamed(ProfileRoutes.profileInfo);
    if (!context.mounted) return;
    unawaited(accountCubit.load());
  }

  String get _vehicleSummary {
    final vehicle = _vehicleType.trim();
    final plate = _plateNumber.trim();
    if (vehicle.isEmpty && plate.isEmpty) {
      return 'No registered vehicle information';
    }
    if (vehicle.isEmpty) return 'Plate number $plate';
    if (plate.isEmpty) return vehicle;
    return '$vehicle · Plate $plate';
  }

  String get _performanceSummary {
    final rating = _averageRating > 0
        ? _averageRating.toStringAsFixed(1)
        : _rating;
    return '$_completedTrips of $_totalTrips trips · $rating rating · ${formatPesoAmount(_lifetimeEarnings)} lifetime';
  }

  Widget _buildMenuGroup(List<_DriverAccountMenuItem> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _buildMenuTile(items[index]),
          if (index != items.length - 1)
            Divider(
              height: 1,
              indent: 2,
              endIndent: 2,
              color: AppTheme.borderSide.withValues(alpha: 0.65),
            ),
        ],
      ],
    );
  }

  void _showVehicleDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('Vehicle Information'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Vehicle Type', _vehicleType),
              const SizedBox(height: 12),
              _detailRow('Plate Number', _plateNumber),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.tertiaryColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value.isEmpty ? 'Unavailable' : value,
            textAlign: TextAlign.end,
            maxLines: 3,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showHelpCenter(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const Text(
          'For ride, payment, or account support, contact the BaoRide operations team from your driver support channel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPerformanceDetails(BuildContext context) {
    final rating = _averageRating > 0
        ? _averageRating.toStringAsFixed(1)
        : _rating;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Rating', rating),
            const SizedBox(height: 12),
            _detailRow('Completed Trips', '$_completedTrips'),
            const SizedBox(height: 12),
            _detailRow('Total Trips', '$_totalTrips'),
            const SizedBox(height: 12),
            _detailRow(
              'Lifetime Earnings',
              formatPesoAmount(_lifetimeEarnings),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w900,
        color: AppTheme.primaryColor.withValues(alpha: 0.42),
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _buildMenuTile(_DriverAccountMenuItem item) {
    return InkWell(
      key: ValueKey<String>('driver-account-item-${item.title}'),
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
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
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: AppTheme.tertiaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              LucideIcons.chevron_right,
              color: AppTheme.primaryColor.withValues(alpha: 0.32),
              size: 23,
            ),
          ],
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
          foregroundColor: AppTheme.cancel,
          side: BorderSide(color: AppTheme.cancel.withValues(alpha: 0.35)),
          backgroundColor: AppTheme.cancel.withValues(alpha: 0.04),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        child: _isLoggingOut
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppTheme.cancel,
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

class _DriverAccountMenuItem {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DriverAccountMenuItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
