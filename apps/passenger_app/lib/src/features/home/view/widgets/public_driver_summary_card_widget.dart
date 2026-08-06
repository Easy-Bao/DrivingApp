import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/home/domain/entities/public_driver_summary.dart';

class PublicDriverSummaryCardWidget extends StatelessWidget {
  final List<PublicDriverSummary> summaries;

  const PublicDriverSummaryCardWidget({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    final visibleSummaries = summaries.take(3).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.shield_check,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'Available driver ratings',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ratings are visible now; exact driver locations stay private until you book.',
            style: TextStyle(
              color: AppTheme.primaryColor.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...visibleSummaries.map(_buildSummaryRow),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(PublicDriverSummary summary) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.user_round,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  summary.vehicleType,
                  style: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.star, size: 15, color: Color(0xFFD99A32)),
          const SizedBox(width: 4),
          Text(
            summary.rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
