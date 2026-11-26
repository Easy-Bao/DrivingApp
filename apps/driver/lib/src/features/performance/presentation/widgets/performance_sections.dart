import 'package:design_system/design_system.dart';
import 'package:driver/src/features/performance/domain/entities/performance_stats.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

class const PerformanceSummarySection({super.key, required this.stats})
    extends StatelessWidget {
  final PerformanceStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final rating = stats.averageRating > 0
        ? stats.averageRating.toStringAsFixed(1)
        : '—';
    final completionRate = stats.standing.completionRatePercent.round();
    final indicatorColor = completionRate >= 85
        ? context.semanticColors.success
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          Semantics(
            header: true,
            child: Text(
              'DRIVER RATING',
              style: textStyles.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                rating,
                style: textStyles.displayLarge?.tabular.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ExcludeSemantics(
                child: Icon(
                  Icons.star_rounded,
                  size: 26,
                  color: context.semanticColors.rating,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    '$completionRate% trip completion',
                    style: textStyles.labelSmall?.tabular.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class const PerformanceMetricsSection({super.key, required this.stats})
    extends StatelessWidget {
  final PerformanceStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final hairlineColor = colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final completed = _MetricColumn(
              icon: LucideIcons.circle_check,
              label: 'Completed trips',
              value: '${stats.completedTrips}',
            );
            final total = _MetricColumn(
              icon: LucideIcons.route,
              label: 'Total trips',
              value: '${stats.totalTrips}',
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  completed,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: hairlineColor,
                    ),
                  ),
                  total,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.lg),
                      child: completed,
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: hairlineColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.lg),
                      child: total,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Divider(height: 1, thickness: 1, color: hairlineColor),
        ),
        Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.wallet_cards,
                  size: 17,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lifetime earnings',
                    style: textStyles.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatPesoAmount(stats.totalEarningsAmount / 100),
                    style: textStyles.headlineSmall?.tabular.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class const _MetricColumn({
  required this.icon,
  required this.label,
  required this.value,
}) extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: Text(
                label,
                style: textStyles.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: textStyles.headlineSmall?.tabular.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class const PerformanceStandingSection({super.key, required this.stats})
    extends StatelessWidget {
  final PerformanceStats stats;

  @override
  Widget build(BuildContext context) {
    final standing = stats.standing;
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Trip reliability',
            style: textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Based on completed and resolved rides. Safety, system, and passenger outcomes are shown separately from driver fault.',
          style: textStyles.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _StandingValue(
          label: 'Completion',
          value: '${standing.completionRatePercent.round()}%',
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: 'Trip completion',
          value: '${standing.completionRatePercent.round()}%',
          child: LinearProgressIndicator(
            value: (standing.completionRatePercent / 100).clamp(0, 1),
            minHeight: 4,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: colorScheme.primary,
            backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StandingValue(
          label: 'Driver-attributed cancellations',
          value: '${standing.driverFaultCancellations}',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StandingChip(
              label: 'Passenger attributed',
              value: standing.passengerFaultCancellations,
            ),
            _StandingChip(
              label: 'Safety / no fault',
              value:
                  standing.safetyRelatedCancellations +
                  standing.noFaultCancellations +
                  standing.systemFaultCancellations,
            ),
            if (standing.pendingReviewCancellations > 0)
              _StandingChip(
                label: 'Pending review',
                value: standing.pendingReviewCancellations,
              ),
          ],
        ),
      ],
    );
  }
}

class const _StandingValue({required this.label, required this.value})
    extends StatelessWidget {
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style: context.textStyles.labelLarge?.tabular.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class const _StandingChip({required this.label, required this.value})
    extends StatelessWidget {
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        '$label: $value',
        style: context.textStyles.labelSmall?.tabular.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class const PerformanceRatingDistribution({super.key, required this.stats})
    extends StatefulWidget {
  final PerformanceStats stats;

  @override
  State<PerformanceRatingDistribution> createState() =>
      _PerformanceRatingDistributionState();
}

class _PerformanceRatingDistributionState
    extends State<PerformanceRatingDistribution> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final distribution = widget.stats.ratingDistribution;
    if (distribution.every((count) => count == 0)) {
      return const SizedBox.shrink();
    }
    final total = distribution.fold<int>(0, (sum, count) => sum + count);
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _isExpanded,
            label: 'Rating breakdown',
            child: InkWell(
              key: const ValueKey<String>('driver-performance-rating-toggle'),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return colorScheme.primary.withValues(alpha: 0.12);
                }
                return Colors.transparent;
              }),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSize.minimumTouchTarget + 8,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rating breakdown',
                          style: textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ExcludeSemantics(
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0.0,
                          duration: animationDuration,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            LucideIcons.chevron_down,
                            size: 17,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      children: [
                        for (
                          var index = distribution.length - 1;
                          index >= 0;
                          index--
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == 0 ? 0 : AppSpacing.sm + 2,
                            ),
                            child: _RatingDistributionRow(
                              stars: index + 1,
                              count: distribution[index],
                              fraction: total == 0
                                  ? 0
                                  : distribution[index] / total,
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class const _RatingDistributionRow({
  required this.stars,
  required this.count,
  required this.fraction,
}) extends StatelessWidget {
  final int stars;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final labelWidth = textScaler.scale(48).clamp(48.0, 96.0);
    final countWidth = textScaler.scale(32).clamp(32.0, 72.0);
    return Row(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: labelWidth),
          child: Text(
            '$stars star',
            maxLines: 1,
            softWrap: false,
            style: context.textStyles.labelMedium?.tabular.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: colorScheme.outlineVariant.withValues(
                alpha: 0.45,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                context.semanticColors.rating,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: countWidth),
          child: Text(
            '$count',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.end,
            style: context.textStyles.labelMedium?.tabular.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
