import 'dart:async';

import 'package:BaoRide/core/services/location_service.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:BaoRide/features/driver/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:BaoRide/features/driver/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Timer? _rideTriggerTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rideTriggerTimer?.cancel();
    super.dispose();
  }

  void _toggleOnline(BuildContext context, bool currentOnline) {
    final lat = LocationService.lastPosition?.latitude ?? 7.828282;
    final lng = LocationService.lastPosition?.longitude ?? 123.434343;

    BlocProvider.of<DashboardCubit>(context).toggleOnline(lat: lat, lng: lng);

    if (!currentOnline) {
      _rideTriggerTimer?.cancel();
      _rideTriggerTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        final s = BlocProvider.of<DashboardCubit>(context).state;
        if (s.isOnline) context.pushNamed('RideAlert');
      });
    } else {
      _rideTriggerTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(state),
                const SizedBox(height: 20),
                _buildStatsRow(state),
                const SizedBox(height: 16),
                if (state.isOnline) _buildRouteOptimizerBanner(context),
                const Spacer(),
                _buildStatusIndicator(state),
                const Spacer(),
                _buildToggleButton(context, state),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(DashboardState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_greeting()},',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Driver Xyrel',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          _StatusPill(
            isOnline: state.isOnline,
            isLoading: state.isLoadingHeatmap,
          ),
        ],
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(DashboardState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderSide),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: state.isLoadingStats
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Row(
                children: [
                  _StatCell(
                    value: '₱${state.todayEarnings.toStringAsFixed(0)}',
                    label: 'Earnings',
                    icon: LucideIcons.banknote,
                  ),
                  _Divider(),
                  _StatCell(
                    value: '${state.todayTrips}',
                    label: 'Trips',
                    icon: LucideIcons.route,
                  ),
                  _Divider(),
                  _StatCell(
                    value: '${state.hoursOnline.toStringAsFixed(1)}h',
                    label: 'Online',
                    icon: LucideIcons.clock,
                  ),
                ],
              ),
      ),
    );
  }

  // ── Route Optimizer Banner ────────────────────────────────────────────────

  Widget _buildRouteOptimizerBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => context.pushNamed('RouteOptimizer'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Route Optimizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status Indicator ──────────────────────────────────────────────────────

  Widget _buildStatusIndicator(DashboardState state) {
    if (state.isOnline) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => Opacity(
          opacity: 0.4 + _pulseCtrl.value * 0.6,
          child: Column(
            children: [
              Icon(LucideIcons.radar, size: 34, color: AppTheme.complete),
              const SizedBox(height: 10),
              Text(
                'Looking for rides...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.complete,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Icon(
          LucideIcons.moon,
          size: 34,
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
        const SizedBox(height: 10),
        Text(
          "You're offline",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Go online to start receiving rides',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  // ── Toggle Button ─────────────────────────────────────────────────────────

  Widget _buildToggleButton(BuildContext context, DashboardState state) {
    final isOnline = state.isOnline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => _toggleOnline(context, isOnline),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: isOnline ? AppTheme.cancel : AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: (isOnline ? AppTheme.cancel : AppTheme.primaryColor)
                    .withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isOnline ? 'Go Offline' : 'Go Online',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets — each has a single responsibility
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline, required this.isLoading});

  final bool isOnline;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline
            ? AppTheme.complete.withValues(alpha: 0.1)
            : AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOnline && isLoading)
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(AppTheme.complete),
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? AppTheme.complete : AppTheme.cancel,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isOnline ? AppTheme.complete : AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.tertiaryColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppTheme.borderSide);
  }
}
