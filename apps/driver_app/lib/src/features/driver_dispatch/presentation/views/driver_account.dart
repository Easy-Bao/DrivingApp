import 'package:driver_app/src/core/di/service_locator.dart';
import 'package:driver_app/src/core/services/auth_api_service.dart';
import 'package:driver_app/src/core/services/trip_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

/// Driver Account component defining application state or layout.
class DriverAccountScreen extends StatefulWidget {
  const DriverAccountScreen({super.key});

  @override
  State<DriverAccountScreen> createState() => _DriverAccountScreenState();
}

class _DriverAccountScreenState extends State<DriverAccountScreen> {
  String _name = '';
  String _vehicleType = '';
  String _plateNumber = '';
  String _rating = '5.0';

  int? _totalTrips;
  double? _lifetimeEarnings;
  double? _acceptanceRate;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _fetchUpdatedData();
  }

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _name = prefs.getString('driver_name') ?? 'Driver';
        _vehicleType = prefs.getString('vehicle_type') ?? 'Bao Bao';
        _plateNumber = prefs.getString('plate_number') ?? 'ABC 1234';
        _rating = prefs.getString('rating') ?? '5.0';
      });
    }
  }

  Future<void> _fetchUpdatedData() async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driver_id') ?? '';
    if (driverId.isEmpty) return;

    final profile = await getIt<AuthApiService>().fetchProfile(driverId);
    if (profile != null && mounted) {
      setState(() {
        _name = profile['name'] as String? ?? _name;
        _vehicleType = profile['vehicleType'] as String? ?? _vehicleType;
        _plateNumber = profile['plateNumber'] as String? ?? _plateNumber;
        _rating = (profile['rating'] ?? 5.0).toString();
      });
      await prefs.setString('driver_name', _name);
      await prefs.setString('vehicle_type', _vehicleType);
      await prefs.setString('plate_number', _plateNumber);
      await prefs.setString('rating', _rating);
    }

    final stats = await getIt<TripApiService>().fetchStats(driverId);
    if (stats != null && mounted) {
      setState(() {
        _totalTrips = stats['totalTrips'] as int?;
        _lifetimeEarnings = (stats['lifetimeEarnings'] as num?)?.toDouble();
        _acceptanceRate = (stats['acceptanceRate'] as num?)?.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          physics: const BouncingScrollPhysics(),
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 28),
            _buildSectionLabel('ACTIVITY'),
            const SizedBox(height: 12),
            ..._buildActivityItems(context).map((item) => _tile(context, item)),
            const SizedBox(height: 24),
            _buildSectionLabel('ACCOUNT'),
            const SizedBox(height: 12),
            ..._buildAccountItems(context).map((item) => _tile(context, item)),
            const SizedBox(height: 32),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  List<_DriverAccountMenuItem> _buildActivityItems(BuildContext context) {
    return [
      _DriverAccountMenuItem(
        icon: LucideIcons.history,
        title: 'Trip History',
        subtitle: 'View past rides',
        onTap: () => context.pushNamed('DriverTripHistory'),
      ),
      _DriverAccountMenuItem(
        icon: LucideIcons.wallet,
        title: 'Earnings',
        subtitle: 'View earnings breakdown',
        onTap: () => context.goNamed('DriverEarnings'),
      ),
    ];
  }

  List<_DriverAccountMenuItem> _buildAccountItems(BuildContext context) {
    return [
      _DriverAccountMenuItem(
        icon: LucideIcons.shield_check,
        title: 'Vehicle Info',
        subtitle: 'Plate: $_plateNumber, Type: $_vehicleType',
        onTap: () {},
      ),
      _DriverAccountMenuItem(
        icon: LucideIcons.message_circle_question_mark,
        title: 'Help Center',
        subtitle: 'Support and FAQs',
        onTap: () {},
      ),
      _DriverAccountMenuItem(
        icon: LucideIcons.info,
        title: 'About BaoRide',
        subtitle: 'Version 1.0.0',
        onTap: () {},
      ),
    ];
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSide),
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
            child: const Icon(
              LucideIcons.user,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.isEmpty ? 'Driver' : _name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_vehicleType  •  $_plateNumber',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.tertiaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.complete.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '★ $_rating',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.complete,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final tripsStr = _totalTrips != null ? _totalTrips.toString() : '0';
    final earningsStr = _lifetimeEarnings != null
        ? '₱${_lifetimeEarnings!.toStringAsFixed(0)}'
        : '₱0';
    final acceptanceStr = _acceptanceRate != null
        ? '${_acceptanceRate!.toStringAsFixed(0)}%'
        : '0%';

    return Row(
      children: [
        _statCard(tripsStr, 'Total Trips'),
        const SizedBox(width: 12),
        _statCard(earningsStr, 'Lifetime Earn.'),
        const SizedBox(width: 12),
        _statCard(acceptanceStr, 'Acceptance'),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderSide),
        ),
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
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Widget _tile(BuildContext context, _DriverAccountMenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 18, color: AppTheme.primaryColor),
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
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
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
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed('Signin'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cancel.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.log_out, size: 16, color: AppTheme.cancel),
              const SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.cancel,
                ),
              ),
            ],
          ),
        ),
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
