import 'package:flutter/material.dart';
import 'package:design_system/src/theme/theme_context.dart';

class const CompactRouteTimeline({
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
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final layoutScale = textScale > 1 ? textScale : 1.0;
    return SizedBox(
      height: 82 * layoutScale,
      child: Stack(
        children: [
          Positioned(
            left: 9.5,
            top: 20.5 * layoutScale + 10,
            bottom: 20.5 * layoutScale + 10,
            child: CustomPaint(
              size: Size(1, 42 * layoutScale),
              painter: _DashedLinePainter(color: colors.outlineVariant),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: _RouteStopRow(
                  isPickup: true,
                  label: pickupLabel,
                  value: pickup,
                  layoutScale: layoutScale,
                ),
              ),
              Expanded(
                child: _RouteStopRow(
                  isPickup: false,
                  label: dropoffLabel,
                  value: dropoff,
                  layoutScale: layoutScale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class const _RouteStopRow({
  required this.isPickup,
  required this.label,
  required this.value,
  required this.layoutScale,
}) extends StatelessWidget {
  final bool isPickup;
  final String label;
  final String value;
  final double layoutScale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 20,
          child: Center(child: RouteStopMarker(isPickup: isPickup, size: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RouteStopText(label: label, value: value),
        ),
      ],
    );
  }
}

/// Filled route pins shared by booking and receipt summaries.
class const RouteStopMarker({super.key, required this.isPickup, this.size = 20})
    extends StatelessWidget {
  final bool isPickup;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RoutePinPainter(
        color: isPickup
            ? context.colorScheme.onSurface
            : context.semanticColors.success,
        centerColor: context.colorScheme.surface,
      ),
    ),
  );
}

class _RoutePinPainter extends CustomPainter {
  const _RoutePinPainter({required this.color, required this.centerColor});
  final Color color;
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 20;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(10, 8), 7, paint);
    canvas.drawPath(
      Path()
        ..moveTo(7, 13)
        ..lineTo(10, 19)
        ..lineTo(13, 13)
        ..close(),
      paint,
    );
    canvas.drawCircle(const Offset(10, 8), 3, Paint()..color = centerColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoutePinPainter oldDelegate) =>
      color != oldDelegate.color || centerColor != oldDelegate.centerColor;
}

class const _RouteStopText({required this.label, required this.value})
    extends StatelessWidget {
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
