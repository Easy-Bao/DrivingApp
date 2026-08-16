import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class RideTripSummaryWidget extends StatelessWidget {
  final String pickupLabel;
  final String destinationName;
  final String destinationAddress;

  const RideTripSummaryWidget({
    super.key,
    required this.pickupLabel,
    required this.destinationName,
    required this.destinationAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRIP DETAILS',
            style: TextStyle(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _TripLocationTimeline(
            pickupLabel: pickupLabel,
            destinationName: destinationName,
            destinationAddress: destinationAddress,
          ),
        ],
      ),
    );
  }
}

class _TripLocationTimeline extends StatelessWidget {
  static const _routeGap = 38.0;

  final String pickupLabel;
  final String destinationName;
  final String destinationAddress;

  const _TripLocationTimeline({
    required this.pickupLabel,
    required this.destinationName,
    required this.destinationAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: 18,
                child: Column(
                  children: [
                    _LocationIcon(icon: LucideIcons.locate_fixed),
                    Expanded(child: _DashedRouteConnector()),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: _routeGap),
                  child: _LocationDetails(label: 'Pickup', value: pickupLabel),
                ),
              ),
            ],
          ),
        ),
        _LocationRow(
          icon: LucideIcons.map_pin,
          label: 'Destination',
          value: destinationName,
          subtitle: destinationAddress,
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LocationIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: _LocationDetails(
            label: label,
            value: value,
            subtitle: subtitle,
          ),
        ),
      ],
    );
  }
}

class _LocationIcon extends StatelessWidget {
  final IconData icon;

  const _LocationIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Icon(icon, size: 18, color: AppTheme.primaryColor),
    );
  }
}

class _LocationDetails extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _LocationDetails({
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle case final address? when address.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.primaryColor.withValues(alpha: 0.58),
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class _DashedRouteConnector extends StatelessWidget {
  const _DashedRouteConnector();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;
        return Center(
          child: SizedBox(
            width: 2,
            height: height,
            child: CustomPaint(
              key: const ValueKey('trip-route-dashes'),
              painter: _DashedRoutePainter(),
            ),
          ),
        );
      },
    );
  }
}

class _DashedRoutePainter extends CustomPainter {
  static const _dashHeight = 4.0;
  static const _gapHeight = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.tertiaryColor.withValues(alpha: 0.68);

    var top = 0.0;
    while (top < size.height) {
      final bottom = (top + _dashHeight).clamp(0.0, size.height).toDouble();
      if (bottom > top) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, top, size.width, bottom - top),
            Radius.circular(size.width / 2),
          ),
          paint,
        );
      }
      top += _dashHeight + _gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoutePainter oldDelegate) => false;
}

@Preview(
  group: 'Trip selection',
  name: 'Long destination address',
  size: Size(390, 280),
)
Widget rideTripSummaryLongAddressPreview() {
  return MaterialApp(
    theme: AppTheme.themeData,
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: RideTripSummaryWidget(
          pickupLabel: 'Mountain View',
          destinationName: 'Silicon Valley Corporate Catering',
          destinationAddress:
              '1390 Pear Avenue, Mountain View, California 94043, United States',
        ),
      ),
    ),
  );
}
