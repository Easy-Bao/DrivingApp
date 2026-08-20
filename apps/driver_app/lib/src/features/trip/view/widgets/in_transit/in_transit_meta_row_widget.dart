import 'package:driver_app/src/core/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_core/shared_core.dart';

class InTransitMetaRowWidget extends StatelessWidget {
  final double distanceKm;
  final String durationText;
  final double fareAmount;

  const InTransitMetaRowWidget({
    super.key,
    required this.distanceKm,
    required this.durationText,
    required this.fareAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(
          LucideIcons.map_pin,
          DistanceFormatter.fromKilometers(distanceKm),
        ),
        const SizedBox(width: 8),
        _buildChip(LucideIcons.clock, durationText),
        const SizedBox(width: 8),
        _buildChip(LucideIcons.banknote, '₱${fareAmount.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: AppTheme.tertiaryColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
