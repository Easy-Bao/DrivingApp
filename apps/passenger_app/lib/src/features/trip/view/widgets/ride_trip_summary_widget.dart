import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class RideTripSummaryWidget extends StatelessWidget {
  final String pickupLabel;
  final String destinationName;
  final String destinationAddress;
  final String distance;
  final String duration;

  const RideTripSummaryWidget({
    super.key,
    required this.pickupLabel,
    required this.destinationName,
    required this.destinationAddress,
    required this.distance,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRIP DETAILS',
            style: TextStyle(
              color: AppTheme.primaryColor.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          _LocationRow(
            icon: LucideIcons.locate_fixed,
            label: 'Pickup',
            value: pickupLabel,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(width: 1, height: 12, color: AppTheme.borderSide),
          ),
          _LocationRow(
            icon: LucideIcons.map_pin,
            label: 'Destination',
            value: destinationName,
            subtitle: destinationAddress,
          ),
          if (distance.isNotEmpty || duration.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (distance.isNotEmpty)
                  _TripStat(icon: LucideIcons.route, value: distance),
                if (distance.isNotEmpty && duration.isNotEmpty)
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: AppTheme.borderSide,
                  ),
                if (duration.isNotEmpty)
                  _TripStat(icon: LucideIcons.clock, value: duration),
              ],
            ),
          ],
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
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
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
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _TripStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
