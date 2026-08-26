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
  String _email = '';
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
    _email = account.email;
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.background,
          title: const Text('Account'),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? 16.0
                  : 24.0;
              final compact = constraints.maxHeight < 650;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 6 : 12,
                  horizontalPadding,
                  MediaQuery.paddingOf(context).bottom + 78,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileSummary(
                          context: context,
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 10 : 14),
                        _buildVehicleSummary(compact: compact),
                        SizedBox(height: compact ? 12 : 18),
                        _buildSectionLabel('Performance'),
                        const SizedBox(height: 6),
                        _buildStatsCard(compact: compact),
                        SizedBox(height: compact ? 12 : 18),
                        _buildSectionLabel('Account Settings'),
                        const SizedBox(height: 6),
                        _buildSettingsGroup(
                          _buildAccountItems(context),
                          compact: compact,
                        ),
                        const Spacer(),
                        SizedBox(height: compact ? 6 : 10),
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummary({
    required BuildContext context,
    required bool compact,
  }) {
    final displayName = _name.isEmpty ? 'Driver' : _name;
    final initial = displayName.substring(0, 1).toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('driver-profile-summary'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => unawaited(_openProfileInfo(context)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: compact ? 46 : 52,
                height: compact ? 46 : 52,
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: compact ? 18 : 21,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 17 : 19,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _email.isEmpty ? 'Driver Account' : _email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.tertiaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ratingBadge(),
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

  Widget _buildVehicleSummary({required bool compact}) {
    return Row(
      children: [
        const Icon(
          LucideIcons.car_front,
          size: 17,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _vehicleDetail(
            'Vehicle',
            _vehicleType.isEmpty ? 'Unavailable' : _vehicleType,
          ),
        ),
        Container(
          width: 1,
          height: compact ? 30 : 34,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: AppTheme.borderSide,
        ),
        Expanded(
          child: _vehicleDetail(
            'Plate Number',
            _plateNumber.isEmpty ? 'Unavailable' : _plateNumber,
          ),
        ),
      ],
    );
  }

  Widget _vehicleDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.tertiaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _ratingBadge() {
    final rating = _averageRating > 0
        ? _averageRating.toStringAsFixed(1)
        : _rating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.secondarySurface,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
          const SizedBox(width: 3),
          Text(
            rating,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 9 : 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
        children: [
          _statItem('$_completedTrips', 'Completed'),
          _statDivider(),
          _statItem('$_totalTrips', 'Total Trips'),
          _statDivider(),
          _statItem(formatPesoAmount(_lifetimeEarnings), 'Lifetime'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor.withValues(alpha: 0.48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 28, color: AppTheme.borderSide);
  }

  Widget _buildSettingsGroup(
    List<_DriverAccountMenuItem> items, {
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

  List<_DriverAccountMenuItem> _buildAccountItems(BuildContext context) {
    return [
      _DriverAccountMenuItem(
        icon: LucideIcons.car_front,
        title: 'Vehicle Information',
        subtitle: 'Review your registered vehicle',
        onTap: () => _showVehicleDetails(context),
      ),
      _DriverAccountMenuItem(
        icon: LucideIcons.message_circle_question_mark,
        title: 'Help Center',
        subtitle: 'Support and frequently asked questions',
        onTap: () => _showHelpCenter(context),
      ),
      _DriverAccountMenuItem(
        icon: LucideIcons.info,
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
    ];
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.primaryColor.withValues(alpha: 0.38),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildMenuTile(_DriverAccountMenuItem item, {required bool compact}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: item.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 17, color: AppTheme.primaryColor),
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
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              size: 15,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoggingOut ? null : () => _handleLogout(context),
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
      label: Text(_isLoggingOut ? 'Logging Out…' : 'Log Out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.cancel,
        side: BorderSide(color: AppTheme.cancel.withValues(alpha: 0.25)),
        backgroundColor: AppTheme.cancel.withValues(alpha: 0.06),
      ),
    );
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DriverAccountMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
