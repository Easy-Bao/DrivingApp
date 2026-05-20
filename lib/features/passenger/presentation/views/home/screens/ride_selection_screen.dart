import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:BaoRide/core/models/place_model.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class RideSelectionScreen extends StatefulWidget {
  final PlaceModel destination;
  final String distance;
  final String duration;
  final double distanceKm;

  const RideSelectionScreen({
    super.key,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.distanceKm,
  });

  @override
  State<RideSelectionScreen> createState() => _RideSelectionScreenState();
}

class _RideSelectionScreenState extends State<RideSelectionScreen> {
  int _selectedIdx = 0;

  late final List<_RideOption> _options;

  @override
  void initState() {
    super.initState();
    final km = widget.distanceKm;
    _options = [
      _RideOption("Solo Ride", "Direct booking, just you", LucideIcons.bike, 20 + km * 10, "3 min", null),
      _RideOption("Share-Bao", "Pasabay, split the fare", LucideIcons.users, 15 + km * 7, "5 min", "Cheapest"),
      _RideOption("Bao Premium", "Priority pickup, top rated", LucideIcons.crown, 35 + km * 15, "2 min", "Fastest"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sel = _options[_selectedIdx];
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(children: [
        // Map area
        Positioned.fill(
          bottom: MediaQuery.of(context).size.height * 0.55,
          child: Container(
            color: AppTheme.neutralColor,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
              // Origin
              Positioned(left: 40, top: 60, child: _marker(Icons.circle, AppTheme.primaryColor, "Pickup", AppTheme.primaryColor)),
              // Dest
              Positioned(right: 50, bottom: 30, child: _marker(Icons.location_on, AppTheme.tertiaryColor, "Drop-off", AppTheme.tertiaryColor)),
            ]),
          ),
        ),
        // Back button
        SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4))]),
              child: const Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor, size: 20)),
          ),
        )),
        // Bottom sheet
        Align(alignment: Alignment.bottomCenter, child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, -10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppTheme.borderSide, borderRadius: BorderRadius.circular(2)))),
            // Route summary
            Row(children: [
              Column(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
                Container(width: 1, height: 20, color: AppTheme.outlineBorderColor),
                const Icon(Icons.location_on, size: 14, color: AppTheme.tertiaryColor),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Current Location", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                const SizedBox(height: 8),
                Text(widget.destination.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(widget.distance, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.tertiaryColor)),
                const SizedBox(height: 4),
                Text(widget.duration, style: TextStyle(fontSize: 11, color: AppTheme.primaryColor.withValues(alpha: 0.5))),
              ]),
            ]),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text("CHOOSE YOUR RIDE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor.withValues(alpha: 0.4), letterSpacing: 1.2))),
            const SizedBox(height: 8),
            // Ride options
            ...List.generate(_options.length, (i) {
              final o = _options[i];
              final isSel = i == _selectedIdx;
              return GestureDetector(
                onTap: () => setState(() => _selectedIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.primaryColor.withValues(alpha: 0.05) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSel ? AppTheme.primaryColor : AppTheme.borderSide, width: isSel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: isSel ? AppTheme.primaryColor : AppTheme.neutralColor, borderRadius: BorderRadius.circular(14)),
                      child: Icon(o.icon, size: 20, color: isSel ? Colors.white : AppTheme.primaryColor)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(o.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                        if (o.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: o.badge == "Cheapest" ? AppTheme.complete.withValues(alpha: 0.15) : AppTheme.tertiaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8)),
                            child: Text(o.badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: o.badge == "Cheapest" ? AppTheme.complete : AppTheme.tertiaryColor))),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(o.subtitle, style: TextStyle(fontSize: 12, color: AppTheme.primaryColor.withValues(alpha: 0.5))),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text("₱${o.fare.toStringAsFixed(2)}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                      Text("~${o.eta}", style: TextStyle(fontSize: 11, color: AppTheme.primaryColor.withValues(alpha: 0.4))),
                    ]),
                    if (isSel) ...[
                      const SizedBox(width: 10),
                      Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.check, size: 14, color: Colors.white)),
                    ],
                  ]),
                ),
              );
            }),
            // Book button
            SafeArea(child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () => context.pushNamed("FindingDriver", extra: {
                    "rideType": sel.name, "fare": sel.fare, "destination": widget.destination,
                    "distance": widget.distance, "duration": widget.duration,
                  }),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)), elevation: 0),
                  child: Text("Book ${sel.name}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                )),
            )),
          ]),
        )),
      ]),
    );
  }

  Widget _marker(IconData icon, Color color, String label, Color labelColor) {
    return Column(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]),
        child: Icon(icon, size: 10, color: Colors.white)),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: labelColor))),
    ]);
  }
}

class _RideOption {
  final String name, subtitle, eta;
  final IconData icon;
  final double fare;
  final String? badge;
  _RideOption(this.name, this.subtitle, this.icon, this.fare, this.eta, this.badge);
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppTheme.outlineBorderColor.withValues(alpha: 0.2)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 24) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 24) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    final r = Paint()..color = AppTheme.outlineBorderColor.withValues(alpha: 0.12)..strokeWidth = 10..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.35), r);
    canvas.drawLine(Offset(size.width * 0.45, 0), Offset(size.width * 0.45, size.height), r);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.3)..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path()..moveTo(50, 70)..cubicTo(size.width * 0.35, size.height * 0.2, size.width * 0.65, size.height * 0.6, size.width - 50, size.height - 30);
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
