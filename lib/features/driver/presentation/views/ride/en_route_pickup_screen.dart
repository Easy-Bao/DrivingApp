import 'dart:math';
import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class EnRoutePickupScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;
  const EnRoutePickupScreen({super.key, required this.pickup, required this.dropoff, required this.distance, required this.fare, required this.duration});
  @override
  State<EnRoutePickupScreen> createState() => _EnRoutePickupScreenState();
}

class _EnRoutePickupScreenState extends State<EnRoutePickupScreen>
    with TickerProviderStateMixin {
  late AnimationController _moveCtrl;
  late AnimationController _pulseCtrl;
  double _sliderVal = 0;

  @override
  void initState() {
    super.initState();
    _moveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _moveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _confirmArrival() {
    context.pushReplacementNamed("WaitingPassenger", extra: {
      "pickup": widget.pickup, "dropoff": widget.dropoff, "distance": widget.distance, "fare": widget.fare, "duration": widget.duration,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(children: [
        // Map
        Positioned.fill(bottom: 300, child: Container(color: AppTheme.neutralColor, child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _MapGrid())),
          Positioned.fill(child: CustomPaint(painter: _RouteLine())),
          // Animated driver
          AnimatedBuilder(animation: _moveCtrl, builder: (ctx, _) {
            final t = _moveCtrl.value;
            final w = MediaQuery.of(context).size.width;
            final h = MediaQuery.of(context).size.height * 0.35;
            return Positioned(
              left: 40 + (w - 120) * t,
              top: h * 0.3 + sin(t * pi) * h * 0.3,
              child: AnimatedBuilder(animation: _pulseCtrl, builder: (ctx, _) {
                return Transform.scale(scale: 1.0 + _pulseCtrl.value * 0.15,
                  child: Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 16)]),
                    child: const Icon(LucideIcons.bike, size: 16, color: Colors.white)));
              }),
            );
          }),
          // Pickup marker
          Positioned(right: 40, top: 60, child: _marker("Pickup", AppTheme.complete)),
        ]))),
        // Back + ETA
        SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GestureDetector(onTap: () => context.pop(),
              child: Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15)]),
                child: const Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor, size: 20))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15)]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.navigation, size: 14, color: AppTheme.complete),
                const SizedBox(width: 6),
                Text("EN ROUTE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.complete, letterSpacing: 0.5)),
              ])),
          ]))),
        // Bottom panel
        Align(alignment: Alignment.bottomCenter, child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, -10))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppTheme.borderSide, borderRadius: BorderRadius.circular(2)))),
            // Passenger info
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.user, color: AppTheme.primaryColor, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Juan D. Cruz", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                Text(widget.pickup, style: TextStyle(fontSize: 12, color: AppTheme.primaryColor.withValues(alpha: 0.5)), overflow: TextOverflow.ellipsis),
              ])),
            ]),
            const SizedBox(height: 16),
            // Call / Chat
            Row(children: [
              Expanded(child: _actionBtn(LucideIcons.phone, "Call", AppTheme.primaryColor, Colors.white, () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calling passenger..."), behavior: SnackBarBehavior.floating));
              })),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(LucideIcons.message_circle, "Chat", AppTheme.neutralColor, AppTheme.primaryColor, () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat coming soon!"), behavior: SnackBarBehavior.floating));
              })),
            ]),
            const SizedBox(height: 20),
            // Slide to arrive
            LayoutBuilder(builder: (ctx, constraints) {
              final maxW = constraints.maxWidth;
              return Container(height: 64, width: maxW,
                decoration: BoxDecoration(color: AppTheme.complete.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(32)),
                child: Stack(children: [
                  // Track
                  Center(child: Text(_sliderVal > 0.8 ? "Release to confirm" : "Slide to confirm arrival",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.complete.withValues(alpha: 0.5)))),
                  // Thumb
                  Positioned(
                    left: _sliderVal * (maxW - 64),
                    child: GestureDetector(
                      onHorizontalDragUpdate: (d) {
                        setState(() => _sliderVal = ((_sliderVal + d.delta.dx / (maxW - 64)).clamp(0.0, 1.0)));
                      },
                      onHorizontalDragEnd: (_) {
                        if (_sliderVal > 0.85) { _confirmArrival(); } else { setState(() => _sliderVal = 0); }
                      },
                      child: Container(width: 64, height: 64,
                        decoration: BoxDecoration(color: AppTheme.complete, borderRadius: BorderRadius.circular(32),
                          boxShadow: [BoxShadow(color: AppTheme.complete.withValues(alpha: 0.3), blurRadius: 12)]),
                        child: const Icon(LucideIcons.chevron_right, color: Colors.white, size: 28)),
                    ),
                  ),
                ]),
              );
            }),
          ]),
        )),
      ]),
    );
  }

  Widget _marker(String label, Color color) {
    return Column(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.person_pin, size: 14, color: Colors.white)),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
    ]);
  }

  Widget _actionBtn(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(height: 48,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24),
        border: bg == AppTheme.neutralColor ? Border.all(color: AppTheme.borderSide) : null),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: fg, size: 18), const SizedBox(width: 8),
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
      ])));
  }
}

class _MapGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppTheme.outlineBorderColor.withValues(alpha: 0.2)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 24) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 24) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppTheme.complete.withValues(alpha: 0.3)..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path()..moveTo(40, size.height * 0.5)..cubicTo(size.width * 0.4, size.height * 0.1, size.width * 0.6, size.height * 0.8, size.width - 40, 70);
    double d = 0;
    for (final m in path.computeMetrics()) {
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 8).clamp(0, m.length).toDouble()), p);
        d += 13;
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
