import 'package:flutter/material.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:shared_ui/shared_ui.dart';

class MapSelectionMarkerWidget extends StatelessWidget {
  static const double width = 32;
  static const double height = 38;
  static const Color markerColor = TripMapMarkerStyle.tripLocation;

  const MapSelectionMarkerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Selected map location',
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _MapSelectionMarkerPainter(
            shadowColor: context.colorScheme.onSurface.withValues(alpha: 0.26),
            surfaceColor: context.colorScheme.surface,
          ),
        ),
      ),
    );
  }
}

class _MapSelectionMarkerPainter extends CustomPainter {
  final Color shadowColor;
  final Color surfaceColor;

  const _MapSelectionMarkerPainter({
    required this.shadowColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;
    canvas
      ..save()
      ..scale(scale, scale);

    const center = Offset(32, 26);
    final outerTail = Path()
      ..moveTo(center.dx - 10, 41)
      ..lineTo(center.dx, 74)
      ..lineTo(center.dx + 10, 41)
      ..close();
    final innerTail = Path()
      ..moveTo(center.dx - 6, 40)
      ..lineTo(center.dx, 67)
      ..lineTo(center.dx + 6, 40)
      ..close();
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 23))
      ..addPath(outerTail, Offset.zero);

    canvas.drawShadow(shadowPath, shadowColor, 5, true);
    canvas.drawPath(outerTail, Paint()..color = surfaceColor);
    canvas.drawPath(
      innerTail,
      Paint()..color = MapSelectionMarkerWidget.markerColor,
    );
    canvas.drawCircle(center, 23, Paint()..color = surfaceColor);
    canvas.drawCircle(
      center,
      18,
      Paint()..color = MapSelectionMarkerWidget.markerColor,
    );
    canvas.drawCircle(center, 9, Paint()..color = surfaceColor);
    canvas.drawCircle(
      center,
      4,
      Paint()..color = MapSelectionMarkerWidget.markerColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapSelectionMarkerPainter oldDelegate) {
    return oldDelegate.shadowColor != shadowColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}
