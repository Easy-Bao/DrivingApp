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
          _LocationRow(
            icon: LucideIcons.locate_fixed,
            label: 'Pickup',
            value: pickupLabel,
          ),
          const _DashedRouteConnector(),
          _LocationRow(
            icon: LucideIcons.map_pin,
            label: 'Destination',
            value: destinationName,
            subtitle: destinationAddress,
          ),
        ],
      ),
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
        SizedBox(
          width: 18,
          child: Icon(icon, size: 18, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
              if (subtitle case final address?
                  when address.trim().isNotEmpty) ...[
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
          ),
        ),
      ],
    );
  }
}

class _DashedRouteConnector extends StatelessWidget {
  const _DashedRouteConnector();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 8, top: 6, bottom: 6),
      child: SizedBox(
        key: ValueKey('trip-route-dashes'),
        width: 2,
        height: 26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_RouteDash(), _RouteDash(), _RouteDash()],
        ),
      ),
    );
  }
}

class _RouteDash extends StatelessWidget {
  const _RouteDash();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.tertiaryColor.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
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
