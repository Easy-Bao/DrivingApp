import 'dart:async';
import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:BaoRide/core/models/place_model.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class FindingDriverScreen extends StatefulWidget {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;

  const FindingDriverScreen({
    super.key,
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
  });

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late AnimationController _dotCtrl;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _navTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      context.pushReplacementNamed("DriverMatched", extra: {
        "rideType": widget.rideType,
        "fare": widget.fare,
        "destination": widget.destination,
        "distance": widget.distance,
        "duration": widget.duration,
      });
    });
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _dotCtrl.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(children: [
        // Map bg
        Positioned.fill(child: Container(color: AppTheme.neutralColor, child: CustomPaint(painter: _BgPainter()))),
        // Radar animation
        Center(child: AnimatedBuilder(
          animation: _radarCtrl,
          builder: (ctx, _) {
            return Stack(alignment: Alignment.center, children: [
              ...List.generate(3, (i) {
                final t = (_radarCtrl.value + i * 0.33) % 1.0;
                return Container(
                  width: 60 + t * 200, height: 60 + t * 200,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15 * (1 - t)), width: 2)),
                );
              }),
              Container(width: 60, height: 60,
                decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20)]),
                child: const Icon(LucideIcons.navigation, color: Colors.white, size: 24)),
            ]);
          },
        )),
        // Back
        SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(onTap: () => context.pop(),
            child: Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4))]),
              child: const Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor, size: 20))))),
        // Bottom
        Align(alignment: Alignment.bottomCenter, child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: BoxDecoration(color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, -10))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppTheme.borderSide, borderRadius: BorderRadius.circular(2)))),
            AnimatedBuilder(animation: _dotCtrl, builder: (ctx, _) {
              final dots = "." * (1 + (_dotCtrl.value * 3).floor());
              return Text("Finding your driver$dots", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryColor));
            }),
            const SizedBox(height: 8),
            Text("Looking for ${widget.rideType} drivers nearby", style: TextStyle(fontSize: 14, color: AppTheme.primaryColor.withValues(alpha: 0.5))),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.neutralColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderSide)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(LucideIcons.map_pin, size: 16, color: AppTheme.tertiaryColor),
                  const SizedBox(width: 8),
                  SizedBox(width: 160, child: Text(widget.destination.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                    overflow: TextOverflow.ellipsis)),
                ]),
                Text("₱${widget.fare.toStringAsFixed(2)}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
              ])),
            const SizedBox(height: 20),
            GestureDetector(onTap: () => context.pop(),
              child: Container(width: double.infinity, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: AppTheme.cancel.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(32)),
                child: Text("Cancel Search", style: TextStyle(color: AppTheme.cancel, fontWeight: FontWeight.w700, fontSize: 15)))),
          ]),
        )),
      ]),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppTheme.outlineBorderColor.withValues(alpha: 0.2)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 24) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 24) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    final r = Paint()..color = AppTheme.outlineBorderColor.withValues(alpha: 0.12)..strokeWidth = 10..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), r);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), r);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), r);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
