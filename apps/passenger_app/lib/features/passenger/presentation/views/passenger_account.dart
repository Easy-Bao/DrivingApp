/// Passenger Account Screen: displays account settings, support information, and handles logging out.
library;
import 'dart:async';
import 'package:passenger_app/core/services/passenger_api_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerAccountScreen extends StatefulWidget {
  const PassengerAccountScreen({super.key});

  @override
  State<PassengerAccountScreen> createState() => _PassengerAccountScreenState();
}

class _PassengerAccountScreenState extends State<PassengerAccountScreen> {
  String _name = '';
  String _phone = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  /// Loads passenger profile from SharedPreferences first for instant display,
  /// then refreshes from the backend and caches the latest values.
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    // Render cached values immediately (fast first paint).
    if (mounted) {
      setState(() {
        _name = prefs.getString('passenger_name') ?? '';
        _phone = prefs.getString('passenger_phone') ?? '';
        _email = prefs.getString('passenger_email') ?? '';
      });
    }

    // Sync from server and update cache.
    final passengerId = prefs.getString('passenger_id') ?? '';
    if (passengerId.isEmpty) return;

    final profile = await PassengerApiService.getPassengerProfile(passengerId);
    if (profile == null || !mounted) return;

    final name = profile['name'] as String? ?? _name;
    final phone = profile['phone'] as String? ?? _phone;
    final email = profile['email'] as String? ?? _email;

    await prefs.setString('passenger_name', name);
    await prefs.setString('passenger_phone', phone);
    await prefs.setString('passenger_email', email);

    if (mounted) {
      setState(() {
        _name = name;
        _phone = phone;
        _email = email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildProfileHeader(),
              const SizedBox(height: 40),
              _buildSectionTitle('Activity'),
              ..._buildActivityItems(context).map((item) => _buildAccountTile(context, item)),
              const SizedBox(height: 32),
              _buildSectionTitle('Personal'),
              ..._buildPersonalItems(context).map((item) => _buildAccountTile(context, item)),
              const SizedBox(height: 32),
              _buildSectionTitle('Support'),
              ..._buildSupportItems(context).map((item) => _buildAccountTile(context, item)),
              const SizedBox(height: 40),
              _buildLogoutButton(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  List<_AccountMenuItem> _buildActivityItems(BuildContext context) {
    return [
      _AccountMenuItem(
        icon: LucideIcons.history,
        title: 'Ride History',
        subtitle: 'View your past trips',
        onTap: () => context.pushNamed('RideHistory'),
      ),
    ];
  }

  List<_AccountMenuItem> _buildPersonalItems(BuildContext context) {
    return [
      _AccountMenuItem(
        icon: LucideIcons.user,
        title: 'Profile Info',
        subtitle: 'Update name and details',
        onTap: () async {
          await context.pushNamed('ProfileInfo');
          unawaited(_loadProfile());
        },
      ),
    ];
  }

  List<_AccountMenuItem> _buildSupportItems(BuildContext context) {
    return [
      _AccountMenuItem(
        icon: LucideIcons.message_circle_question_mark,
        title: 'Help Center',
        subtitle: 'Get support and FAQs',
        onTap: () => context.pushNamed('HelpCenter'),
      ),
      _AccountMenuItem(
        icon: LucideIcons.info,
        title: 'About BaoRide',
        subtitle: 'Version 1.0.0',
        onTap: () {},
      ),
    ];
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSide, width: 2),
            ),
            child: const Icon(
              LucideIcons.user,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _name.isNotEmpty ? _name : '—',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _phone.isNotEmpty ? _phone : '—',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_email.isNotEmpty) ...
            [
              const SizedBox(height: 2),
              Text(
                _email,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    _AccountMenuItem item,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: AppTheme.primaryColor,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: TextStyle(
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevron_right,
        size: 18,
        color: AppTheme.borderSide,
      ),
      onTap: item.onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (!mounted) return;
          context.goNamed('Signin');
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.log_out, size: 18),
            SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    );
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
