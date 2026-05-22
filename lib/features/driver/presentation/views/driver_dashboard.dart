import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:BaoRide/core/services/map_provider.dart';
import 'package:BaoRide/core/services/location_service.dart';
import 'package:BaoRide/features/driver/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:BaoRide/features/driver/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:BaoRide/src/rust/models/fare_models.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Screen displayed as the driver's primary control panel.
/// Visualizes surge cells dynamically calculated by Rust KDE onto a Mapbox map.
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  AppMapController? _mapController;
  bool _initialized = false;
  Timer? _rideTriggerTimer;

  // Simulated stats
  final double _todayEarnings = 385.50;
  final int _todayTrips = 7;
  final double _hoursOnline = 4.5;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rideTriggerTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    if (!_initialized) {
      _initialized = true;
      final defaultLat = LocationService.lastPosition?.latitude ?? 7.828282;
      final defaultLng = LocationService.lastPosition?.longitude ?? 123.434343;
      MapProvider.addMarker(controller, defaultLat, defaultLng, isOrigin: true);
    }
  }

  void _updateSurgeMarkers(List<HeatmapCell> cells) async {
    if (_mapController == null) return;
    for (final cell in cells) {
      if (cell.intensity > 1.0) {
        // Render hotspots as secondary markers or circles
        await MapProvider.addMarker(
          _mapController!,
          cell.lat,
          cell.lng,
          isOrigin: false,
        );
      }
    }
  }

  void _toggleOnline(bool currentOnline) {
    final defaultLat = LocationService.lastPosition?.latitude ?? 7.828282;
    final defaultLng = LocationService.lastPosition?.longitude ?? 123.434343;

    BlocProvider.of<DashboardCubit>(context).toggleOnline(defaultLat, defaultLng);

    // If switching from offline to online, simulate incoming ride after 4 seconds
    if (!currentOnline) {
      _rideTriggerTimer?.cancel();
      _rideTriggerTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          final cubitState = BlocProvider.of<DashboardCubit>(context).state;
          if (cubitState.isOnline) {
            context.pushNamed("RideAlert");
          }
        }
      });
    } else {
      _rideTriggerTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultLat = LocationService.lastPosition?.latitude ?? 7.828282;
    final defaultLng = LocationService.lastPosition?.longitude ?? 123.434343;

    return BlocConsumer<DashboardCubit, DashboardState>(
      listener: (context, state) {
        if (state.isOnline && state.surgeCells.isNotEmpty) {
          _updateSurgeMarkers(state.surgeCells);
        }
      },
      builder: (context, state) {
        final isOnline = state.isOnline;
        final isLoading = state.isLoading;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: Stack(
            children: [
              // Map background
              Positioned.fill(
                bottom: 0,
                child: Container(
                  color: AppTheme.neutralColor,
                  child: MapProvider.buildMapView(
                    latitude: defaultLat,
                    longitude: defaultLng,
                    zoom: 14.0,
                    interactive: true,
                    onMapCreated: _onMapCreated,
                  ),
                ),
              ),
              
              // Status + content overlay
              SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Good ${_getGreeting()},",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                "Driver Xyrel",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppTheme.complete.withValues(alpha: 0.12)
                                  : AppTheme.primaryColor.withValues(alpha: 0.08),
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
                                  isOnline ? "Online" : "Offline",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isOnline ? AppTheme.complete : AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick stats card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.borderSide),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _statItem(
                              "₱${_todayEarnings.toStringAsFixed(0)}",
                              "Earnings",
                              LucideIcons.banknote,
                            ),
                            Container(width: 1, height: 40, color: AppTheme.borderSide),
                            _statItem("$_todayTrips", "Trips", LucideIcons.route),
                            Container(width: 1, height: 40, color: AppTheme.borderSide),
                            _statItem(
                              "${_hoursOnline}h",
                              "Online",
                              LucideIcons.clock,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isOnline) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: () => context.pushNamed("RouteOptimizer"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.sparkles,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    "Route Optimizer",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevron_right,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),
                    
                    // Status badge overlay
                    if (isOnline)
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (ctx, _) {
                          return Opacity(
                            opacity: 0.4 + _pulseCtrl.value * 0.6,
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.radar,
                                  size: 32,
                                  color: AppTheme.complete,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Looking for rides...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.complete,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      Column(
                        children: [
                          Icon(
                            LucideIcons.moon,
                            size: 32,
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
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
                            "Go online to start receiving rides",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    
                    const Spacer(),

                    // Giant GO button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      child: GestureDetector(
                        onTap: () => _toggleOnline(isOnline),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isOnline ? AppTheme.cancel : AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: (isOnline ? AppTheme.cancel : AppTheme.primaryColor)
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isOnline ? LucideIcons.power : LucideIcons.zap,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isOnline ? "GO OFFLINE" : "GO ONLINE",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
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

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Morning";
    if (h < 17) return "Afternoon";
    return "Evening";
  }
}
