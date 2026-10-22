import 'package:flutter/material.dart';

class const FindingDriverRouteConnector({super.key, required this.color})
    extends StatelessWidget {
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedLinePainter(color: color));
  }
}

class _DashedLinePainter extends CustomPainter {
  static const double _dashHeight = 3.5;
  static const double _gapHeight = 3.5;
  static const double _strokeWidth = 1.5;

  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    double startY = 4.0;
    while (startY < size.height - 4.0) {
      final endY = (startY + _dashHeight).clamp(0.0, size.height - 4.0);
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, endY),
        paint,
      );
      startY += _dashHeight + _gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
