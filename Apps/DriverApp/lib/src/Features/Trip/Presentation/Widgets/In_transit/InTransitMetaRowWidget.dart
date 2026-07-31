import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

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
        _buildChip(LucideIcons.map_pin, '${distanceKm.toStringAsFixed(1)} km'),
        const SizedBox(width: 10),
        _buildChip(LucideIcons.clock, durationText),
        const SizedBox(width: 10),
        _buildChip(LucideIcons.banknote, '₱${fareAmount.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppTheme.tertiaryColor),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
