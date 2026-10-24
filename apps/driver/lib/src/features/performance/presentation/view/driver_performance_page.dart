import 'dart:async';

import 'package:driver/src/features/performance/presentation/bloc/driver_performance_cubit.dart';
import 'package:driver/src/features/performance/presentation/bloc/driver_performance_state.dart';
import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class const PerformancePage({super.key, this.onBack, this.onRefresh})
    extends StatelessWidget {
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppSecondaryPage(
      title: 'Performance',
      onBack: onBack ?? () => context.pop(),
      child: BlocBuilder<PerformanceCubit, PerformanceState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh:
              onRefresh ??
              () => BlocProvider.of<PerformanceCubit>(context).load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppLayout.pagePadding,
              AppLayout.pagePadding,
              AppLayout.pagePadding,
              48,
            ),
            children: [
              if (state.isLoading) const LinearProgressIndicator(),
              if (state.isLoading) const SizedBox(height: 18),
              if (state.stats != null) ...[
                _PerformanceSummary(stats: state.stats),
                const SizedBox(height: AppSpacing.lg),
                _PerformanceMetrics(stats: state.stats),
                const SizedBox(height: AppSpacing.lg),
                _StandingSummary(stats: state.stats),
                const SizedBox(height: AppSpacing.lg),
                _RatingDistribution(stats: state.stats),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppErrorBanner(
                  message: state.errorMessage!,
                  onRetry: () => unawaited(
                    BlocProvider.of<PerformanceCubit>(context).load(),
                  ),
                  onDismiss: () =>
                      BlocProvider.of<PerformanceCubit>(context).dismissError(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class const _PerformanceSummary({required this.stats}) extends StatelessWidget {
  final PerformanceStats? stats;

  @override
  Widget build(BuildContext context) {
    final rating = stats?.averageRating != null && stats!.averageRating > 0
        ? stats!.averageRating.toStringAsFixed(1)
        : '—';
    final completionRate = stats?.standing.completionRatePercent.round() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Text(
            'Driver rating',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rating,
                style: context.textStyles.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.star_rounded,
                size: 24,
                color: context.semanticColors.rating,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$completionRate% trip completion',
              style: context.textStyles.labelSmall?.copyWith(
                color: context.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _RatingDistribution({required this.stats}) extends StatelessWidget {
  final PerformanceStats? stats;

  @override
  Widget build(BuildContext context) {
    final distribution = stats?.ratingDistribution;
    if (distribution == null || distribution.every((count) => count == 0)) {
      return const SizedBox.shrink();
    }
    final total = distribution.fold<int>(0, (sum, count) => sum + count);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text('Rating breakdown', style: context.textStyles.titleMedium),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          for (var index = distribution.length - 1; index >= 0; index--)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RatingDistributionRow(
                stars: index + 1,
                count: distribution[index],
                fraction: total == 0 ? 0 : distribution[index] / total,
              ),
            ),
        ],
      ),
    );
  }
}

class const _StandingSummary({required this.stats}) extends StatelessWidget {
  final PerformanceStats? stats;

  @override
  Widget build(BuildContext context) {
    final standing = stats?.standing;
    if (standing == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trip reliability', style: context.textStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Based on completed and resolved rides. Safety, system, and passenger outcomes are shown separately from driver fault.',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
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
              color: context.colorScheme.primary,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StandingValue(
            label: 'Driver-attributed cancellations',
            value: '${standing.driverFaultCancellations}',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
      ),
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
          style: context.textStyles.labelLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$label: $value',
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
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
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text('$stars star', style: context.textStyles.labelMedium),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.semanticColors.rating,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: context.textStyles.labelMedium,
          ),
        ),
      ],
    );
  }
}

class const _PerformanceMetrics({required this.stats}) extends StatelessWidget {
  final PerformanceStats? stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn =
            constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final cardWidth = useSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _PerformanceMetricCard(
              width: cardWidth,
              icon: LucideIcons.circle_check,
              label: 'Completed trips',
              value: '${stats?.completedTrips ?? 0}',
            ),
            _PerformanceMetricCard(
              width: cardWidth,
              icon: LucideIcons.route,
              label: 'Total trips',
              value: '${stats?.totalTrips ?? 0}',
            ),
            _PerformanceMetricCard(
              width: constraints.maxWidth,
              icon: LucideIcons.wallet_cards,
              label: 'Lifetime earnings',
              value: formatPesoAmount((stats?.totalEarningsAmount ?? 0) / 100),
            ),
          ],
        );
      },
    );
  }
}

class const _PerformanceMetricCard({
  required this.width,
  required this.icon,
  required this.label,
  required this.value,
}) extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: BoxConstraints(
        minHeight: label == 'Lifetime earnings' ? 76 : 104,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: label == 'Lifetime earnings'
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        value,
                        style: context.textStyles.titleLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  icon,
                  size: 20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
    );
  }
}
