import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class const CompactRouteTimelineWidget({
  super.key,
  required this.pickup,
  required this.dropoff,
  this.pickupLabel = 'Pickup',
  this.dropoffLabel = 'Drop Off',
}) extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String pickupLabel;
  final String dropoffLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 82,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 14,
                  bottom: 14,
                  child: CustomPaint(
                    size: const Size(1, 48),
                    painter: _DashedLinePainter(color: colors.outlineVariant),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _StopIcon(
                      icon: LucideIcons.map_pin,
                      color: colors.primary,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _StopIcon(
                      icon: LucideIcons.navigation,
                      color: colors.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RouteStopText(label: pickupLabel, value: pickup),
                _RouteStopText(label: dropoffLabel, value: dropoff),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class const _StopIcon({required this.icon, required this.color})
    extends StatelessWidget {
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 18,
      color: color,
    );
  }
}

class const _RouteStopText({required this.label, required this.value})
    extends StatelessWidget {
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class const _DashedLinePainter({required this.color}) extends CustomPainter {
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashLength = 4.0;
    const gapLength = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dashLength).clamp(0, size.height)),
        paint,
      );
      y += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
