import 'dart:math';
import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:BaoRide/src/rust/application/fare_engine.dart' as rust;

class RouteOptimizerScreen extends StatefulWidget {
  const RouteOptimizerScreen({super.key});
  @override
  State<RouteOptimizerScreen> createState() => _RouteOptimizerScreenState();
}

class _RouteOptimizerScreenState extends State<RouteOptimizerScreen> {
  bool _isOptimizing = false;
  List<rust.Waypoint> _sequence = [];
  double _optimizedDistance = 0.0;

  // Initial list of waypoints (unsorted/raw order)
  final List<rust.Waypoint> _rawWaypoints = const [
    rust.Waypoint(id: "1", name: "Drop-off: Passenger A (Dipolog Market)", lat: 8.5862, lng: 123.3392, isPickup: false, passengerId: "A"),
    rust.Waypoint(id: "2", name: "Pick-up: Passenger B (Galas Port)", lat: 8.5912, lng: 123.3325, isPickup: true, passengerId: "B"),
    rust.Waypoint(id: "3", name: "Pick-up: Passenger A (SM City Dipolog)", lat: 8.5891, lng: 123.3441, isPickup: true, passengerId: "A"),
    rust.Waypoint(id: "4", name: "Drop-off: Passenger B (Sunset Boulevard)", lat: 8.5795, lng: 123.3488, isPickup: false, passengerId: "B"),
  ];

  @override
  void initState() {
    super.initState();
    // Default sequence is raw
    _sequence = List.from(_rawWaypoints);
    _calculateRawDistance();
  }

  void _calculateRawDistance() {
    double d = 0.0;
    double lat = 8.5879; // Driver start
    double lng = 123.3402;
    for (final wp in _rawWaypoints) {
      final latDiff = wp.lat - lat;
      final lngDiff = wp.lng - lng;
      d += 111.0 * sqrt(latDiff * latDiff + lngDiff * lngDiff);
      lat = wp.lat;
      lng = wp.lng;
    }
    setState(() => _optimizedDistance = double.parse(d.toStringAsFixed(1)));
  }

  void _runRustTspOptimizer() async {
    setState(() => _isOptimizing = true);
    
    // Simulate real calculations with a short loading state for UX
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final startLat = 8.5879; // Current driver location
      final startLng = 123.3402;

      final result = await rust.calculateOptimalRoute(
        startLat: startLat,
        startLng: startLng,
        waypoints: _rawWaypoints,
      );

      if (mounted) {
        setState(() {
          _sequence = result.optimalSequence;
          _optimizedDistance = result.totalDistanceKm;
          _isOptimizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Route sequence optimized using Rust TSP solver!"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.complete,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOptimized = _sequence != _rawWaypoints;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text("Share-Bao Optimizer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(children: [
            // Optimizer Info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.neutralColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.borderSide)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("PASSENGERS INBOARD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryColor.withValues(alpha: 0.4), letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    const Text("2 Active Bookings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      "${_optimizedDistance.toStringAsFixed(1)} km total",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _badge("Juan D. Cruz (A)", Colors.indigo),
                  const SizedBox(width: 8),
                  _badge("Maria A. Santos (B)", Colors.teal),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            // Timeline header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("STOP SEQUENCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryColor.withValues(alpha: 0.4), letterSpacing: 0.8)),
              if (hasOptimized)
                Row(children: [
                  Icon(LucideIcons.sparkles, size: 14, color: AppTheme.complete),
                  const SizedBox(width: 4),
                  Text("RUST OPTIMIZED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.complete)),
                ]),
            ]),
            const SizedBox(height: 16),
            // Waypoints Timeline
            Expanded(
              child: ListView.builder(
                itemCount: _sequence.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (ctx, index) {
                  final wp = _sequence[index];
                  final isLast = index == _sequence.length - 1;
                  return _timelineNode(
                    index + 1,
                    wp.name,
                    wp.isPickup,
                    wp.passengerId == "A" ? Colors.indigo : Colors.teal,
                    isLast,
                  );
                },
              ),
            ),
            // Optimize button
            GestureDetector(
              onTap: _isOptimizing ? null : _runRustTspOptimizer,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: hasOptimized ? AppTheme.complete : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: (hasOptimized ? AppTheme.complete : AppTheme.primaryColor).withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: _isOptimizing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(hasOptimized ? LucideIcons.check : LucideIcons.sparkles, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            hasOptimized ? "SEQUENCE OPTIMIZED" : "RUN RUST TSP SOLVER",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (hasOptimized)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _sequence = List.from(_rawWaypoints);
                    _calculateRawDistance();
                  });
                },
                child: Text("Reset Sequence", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor.withValues(alpha: 0.4))),
              ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _timelineNode(int step, String name, bool isPickup, Color passColor, bool isLast) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPickup ? passColor : passColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: passColor, width: 2),
            ),
            child: Center(
              child: Icon(
                isPickup ? LucideIcons.arrow_up_to_line : LucideIcons.arrow_down_to_line,
                size: 14,
                color: isPickup ? Colors.white : passColor,
              ),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: AppTheme.outlineBorderColor.withValues(alpha: 0.4),
              ),
            ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "STOP $step",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: passColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
