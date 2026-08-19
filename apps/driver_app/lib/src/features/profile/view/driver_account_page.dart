import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isRefreshing = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _fetchUpdatedData();
  }

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString('driver_name') ?? '';
      _email = prefs.getString('driver_email') ?? '';
      _vehicleType = prefs.getString('vehicle_type') ?? '';
      _plateNumber = prefs.getString('plate_number') ?? '';
      _rating = prefs.getString('rating') ?? '—';
    });
  }

  Future<void> _fetchUpdatedData() async {
    if (mounted) setState(() => _isRefreshing = true);
    try {
      final driverId =
          await Modular.get<SecureSessionService>().readDriverId() ?? '';
      if (driverId.isEmpty) return;

      final profileData = await Modular.get<DriverRemoteDataSource>()
          .fetchDriverProfile(driverId);
      final prefs = await SharedPreferences.getInstance();
      final name = _readString(profileData, ['name', 'full_name'], _name);
      final vehicleType = _readString(profileData, [
        'vehicleType',
        'vehicle_type',
      ], _vehicleType);
      final plateNumber = _readString(profileData, [
        'plateNumber',
        'plate_number',
      ], _plateNumber);
      final profileRating = _readNumber(profileData, [
        'rating',
        'average_rating',
      ]);
      final rating = profileRating != null && profileRating > 0
          ? profileRating.toStringAsFixed(1)
          : _rating;

      await prefs.setString('driver_name', name);
      await prefs.setString('vehicle_type', vehicleType);
      await prefs.setString('plate_number', plateNumber);
      await prefs.setString('rating', rating);

      final stats = await Modular.get<TripRemoteDataSource>().fetchStats(
        driverId,
      );
      if (!mounted) return;
      final totalFareCentavos = _readNumber(stats, ['total_fare_centavos']);
      setState(() {
        _name = name;
        _vehicleType = vehicleType;
        _plateNumber = plateNumber;
        _rating = rating;
        _totalTrips = _readInt(stats, ['totalTrips', 'total_trips']);
        _completedTrips = _readInt(stats, [
          'completedTrips',
          'completed_trips',
        ]);
        _lifetimeEarnings = totalFareCentavos != null
            ? totalFareCentavos / 100
            : _readNumber(stats, ['lifetimeEarnings']) ?? 0;
        _averageRating =
            _readNumber(stats, ['average_rating']) ?? profileRating ?? 0;
      });
    } catch (error) {
      debugPrint('Unable to refresh driver account: $error');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _readString(
    Map<String, dynamic> values,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = values[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return fallback;
  }

  double? _readNumber(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value is num && value.isFinite) return value.toDouble();
    }
    return null;
  }

  int _readInt(Map<String, dynamic> values, List<String> keys) {
    final value = _readNumber(values, keys);
    return value?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background,
        title: const Text('Account'),
        actions: [
          IconButton(
            tooltip: 'Refresh account',
            onPressed: _isRefreshing ? null : _fetchUpdatedData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.refresh_cw),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;
            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _fetchUpdatedData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  28,
                ),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 18),
                          _buildSectionLabel('Performance'),
                          const SizedBox(height: 8),
                          _buildStatsCard(),
                          const SizedBox(height: 20),
                          _buildSectionLabel('Account settings'),
                          const SizedBox(height: 8),
                          ..._buildAccountItems(context).map(_buildMenuTile),
                          const SizedBox(height: 12),
                          _buildLogoutButton(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final displayName = _name.isEmpty ? 'Driver' : _name;
    final initial = displayName.substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _email.isEmpty ? 'Driver account' : _email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
                _ratingBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _profileMeta(
                      'Vehicle',
                      _vehicleType.isEmpty ? 'Unavailable' : _vehicleType,
                    ),
                  ),
                  _profileDivider(),
                  Expanded(
                    child: _profileMeta(
                      'Plate number',
                      _plateNumber.isEmpty ? 'Unavailable' : _plateNumber,
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

  Widget _profileMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.48),
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
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _profileDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white24,
    );
  }

  Widget _ratingBadge() {
    final rating = _averageRating > 0
        ? _averageRating.toStringAsFixed(1)
        : _rating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$rating rating',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _statItem('$_completedTrips', 'Completed trips'),
            _statDivider(),
            _statItem('$_totalTrips', 'Total trips'),
            _statDivider(),
            _statItem('₱${_lifetimeEarnings.toStringAsFixed(0)}', 'Lifetime'),
          ],
        ),
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
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor.withValues(alpha: 0.48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 32, color: AppTheme.borderSide);
  }

  List<_DriverAccountMenuItem> _buildAccountItems(BuildContext context) {
    return [
      _DriverAccountMenuItem(
        icon: LucideIcons.car_front,
        title: 'Vehicle information',
        subtitle: 'Review your registered vehicle',
        onTap: () => _showVehicleDetails(context),
      ),
      _DriverAccountMenuItem(
        icon: LucideIcons.message_circle_question_mark,
        title: 'Help center',
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
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehicle information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _detailRow('Vehicle type', _vehicleType),
              const SizedBox(height: 12),
              _detailRow('Plate number', _plateNumber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.tertiaryColor)),
        Text(
          value.isEmpty ? 'Unavailable' : value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  void _showHelpCenter(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help center'),
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

  Widget _buildMenuTile(_DriverAccountMenuItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderSide),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor.withValues(alpha: 0.48),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevron_right,
                  size: 16,
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
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
      label: Text(_isLoggingOut ? 'Logging out…' : 'Log out'),
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
