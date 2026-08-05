import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverAccountScreen extends StatefulWidget {
  const DriverAccountScreen({super.key});

  @override
  State<DriverAccountScreen> createState() => _DriverAccountScreenState();
}

class _DriverAccountScreenState extends State<DriverAccountScreen> {
  String _name = '';
  String _vehicleType = '';
  String _plateNumber = '';
  String _rating = '—';

  int _totalTrips = 0;
  int _completedTrips = 0;
  double _lifetimeEarnings = 0;
  double _averageRating = 0;
  bool _isRefreshing = false;

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
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _fetchUpdatedData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildSectionLabel('PERFORMANCE'),
              const SizedBox(height: 12),
              _buildStatsCard(),
              const SizedBox(height: 24),
              _buildSectionLabel('DRIVER ACCOUNT'),
              const SizedBox(height: 12),
              ..._buildAccountItems(context).map(_buildMenuTile),
              const SizedBox(height: 24),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final displayName = _name.isEmpty ? 'Driver' : _name;
    final vehicle = [
      if (_vehicleType.isNotEmpty) _vehicleType,
      if (_plateNumber.isNotEmpty) _plateNumber,
    ].join('  •  ');
    final initial = displayName.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.isEmpty ? 'Vehicle details unavailable' : vehicle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _ratingBadge(),
        ],
      ),
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
        '★ $rating',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
        children: [
          _statItem('$_completedTrips', 'Completed'),
          _statDivider(),
          _statItem('₱${_lifetimeEarnings.toStringAsFixed(0)}', 'Lifetime'),
          _statDivider(),
          _statItem('$_totalTrips', 'Total rides'),
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
      onPressed: () async {
        await Modular.get<SecureSessionService>().clearSession();
        if (context.mounted) context.goNamed(AuthRoutes.signin);
      },
      icon: const Icon(LucideIcons.log_out, size: 17),
      label: const Text('Log out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.cancel,
        side: BorderSide(color: AppTheme.cancel.withValues(alpha: 0.25)),
        backgroundColor: AppTheme.cancel.withValues(alpha: 0.06),
      ),
    );
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
