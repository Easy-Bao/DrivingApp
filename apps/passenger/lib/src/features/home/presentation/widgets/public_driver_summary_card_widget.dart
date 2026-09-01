import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/home/domain/entities/public_driver_summary.dart';
import 'package:design_system/design_system.dart';

class const PublicDriverSummaryCardWidget({super.key, required this.summaries})
    extends StatelessWidget {
  final List<PublicDriverSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final visibleSummaries = summaries.take(3).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.shield_check,
                size: 18,
                color: context.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drivers Nearby (${summaries.length})',
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Available drivers can accept your request. Ratings help you choose after matching.',
            style: TextStyle(
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...visibleSummaries.map(
            (summary) => _buildSummaryRow(context, summary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, PublicDriverSummary summary) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colorScheme.secondaryContainer.withValues(
                alpha: 0.35,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.user_round,
              size: 16,
              color: context.colorScheme.onSurface,
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
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  summary.vehicleType,
                  style: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.star,
            size: 15,
            color: context.semanticColors.rating,
          ),
          const SizedBox(width: 4),
          Text(
            summary.rating.toStringAsFixed(1),
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
