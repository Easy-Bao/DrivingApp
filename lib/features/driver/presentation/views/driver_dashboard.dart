import 'dart:math';
import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:BaoRide/src/rust/application/fare_engine.dart' as rust;

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  late AnimationController _pulseCtrl;
  List<rust.HeatmapCell> _heatmapCells = [];
  bool _isLoadingHeatmap = false;

  // Simulated stats
  final double _todayEarnings = 385.50;
  final int _todayTrips = 7;
  final double _hoursOnline = 4.5;

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
    super.dispose();
  }

  void _loadHeatmap() async {
    if (!_isOnline) return;
    setState(() => _isLoadingHeatmap = true);
    try {
      final centerLat = 8.5879;
      final centerLng = 123.3402;
      final requestLats = [8.5890, 8.5860, 8.5820, 8.5910, 8.5870, 8.5840];
      final requestLngs = [
        123.3420,
        123.3390,
        123.3450,
        123.3370,
        123.3410,
        123.3440,
      ];

      final cells = await rust.calculateSurgeHeatmap(
        centerLat: centerLat,
        centerLng: centerLng,
        gridSize: 12,
        cellSizeDegrees: 0.0015,
        requestLats: requestLats,
        requestLngs: requestLngs,
      );
      if (mounted && _isOnline) {
        setState(() {
          _heatmapCells = cells;
          _isLoadingHeatmap = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHeatmap = false);
    }
  }

  void _toggleOnline() {
    setState(() {
      _isOnline = !_isOnline;
      if (!_isOnline) {
        _heatmapCells = [];
      }
    });
    if (_isOnline) {
      _loadHeatmap();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You're now online! Looking for rides..."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.complete,
          duration: const Duration(seconds: 2),
        ),
      );
      // Simulate incoming ride after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _isOnline) context.pushNamed("RideAlert");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Map background
          Positioned.fill(
            bottom: 0,
            child: Container(
              color: AppTheme.neutralColor,
              child: CustomPaint(
                painter: _DashMapPainter(heatmapCells: _heatmapCells),
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
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? AppTheme.complete.withValues(alpha: 0.12)
                              : AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isOnline && _isLoadingHeatmap)
                              SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.complete,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isOnline
                                      ? AppTheme.complete
                                      : AppTheme.cancel,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? "Online" : "Offline",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isOnline
                                    ? AppTheme.complete
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quick stats
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
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.borderSide,
                        ),
                        _statItem("$_todayTrips", "Trips", LucideIcons.route),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.borderSide,
                        ),
                        _statItem(
                          "${_hoursOnline}h",
                          "Online",
                          LucideIcons.clock,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isOnline) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => context.pushNamed("RouteOptimizer"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.15,
                              ),
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
                // Status text
                if (_isOnline)
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
                    onTap: _toggleOnline,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? AppTheme.cancel
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isOnline
                                        ? AppTheme.cancel
                                        : AppTheme.primaryColor)
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
                              _isOnline ? LucideIcons.power : LucideIcons.zap,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isOnline ? "GO OFFLINE" : "GO ONLINE",
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

class _DashMapPainter extends CustomPainter {
  final List<rust.HeatmapCell> heatmapCells;
  _DashMapPainter({this.heatmapCells = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.outlineBorderColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 28)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);

    final r = Paint()
      ..color = AppTheme.outlineBorderColor.withValues(alpha: 0.1)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      r,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      r,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      r,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      r,
    );

    if (heatmapCells.isNotEmpty) {
      final minLat = heatmapCells.map((c) => c.lat).reduce(min);
      final maxLat = heatmapCells.map((c) => c.lat).reduce(max);
      final minLng = heatmapCells.map((c) => c.lng).reduce(min);
      final maxLng = heatmapCells.map((c) => c.lng).reduce(max);

      final latRange = maxLat - minLat;
      final lngRange = maxLng - minLng;

      for (final cell in heatmapCells) {
        if (cell.intensity <= 1.0) continue;

        final xNorm = latRange == 0 ? 0.5 : (cell.lat - minLat) / latRange;
        final yNorm = lngRange == 0 ? 0.5 : (cell.lng - minLng) / lngRange;

        final cx = 50 + xNorm * (size.width - 100);
        final cy = 150 + yNorm * (size.height - 350);

        final ratio = ((cell.intensity - 1.0) / 1.5).clamp(0.0, 1.0);

        final color = Color.lerp(
          Colors.amber.withValues(alpha: 0.15),
          AppTheme.cancel.withValues(alpha: 0.4),
          ratio,
        )!;

        final radius = 24.0 + ratio * 16.0;
        final paint = Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

        canvas.drawCircle(Offset(cx, cy), radius, paint);

        final corePaint = Paint()
          ..color = Color.lerp(
            Colors.amber.withValues(alpha: 0.3),
            AppTheme.cancel.withValues(alpha: 0.6),
            ratio,
          )!;
        canvas.drawCircle(Offset(cx, cy), radius * 0.4, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashMapPainter oldDelegate) =>
      oldDelegate.heatmapCells != heatmapCells;
}
