import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/performance/domain/entities/performance_stats.dart';
import 'package:driver/src/features/performance/presentation/bloc/performance_cubit.dart';
import 'package:driver/src/features/performance/presentation/bloc/performance_state.dart';
import 'package:driver/src/features/performance/presentation/widgets/performance_sections.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const PerformancePage({super.key, this.onBack, this.onRefresh})
    extends StatelessWidget {
  static const _loadingStats = PerformanceStats(
    todayEarningsAmount: 24500,
    todayCompletedTrips: 4,
    totalTrips: 48,
    completedTrips: 44,
    totalEarningsAmount: 1850000,
    averageRating: 4.9,
    standing: DriverStanding(
      settledTrips: 48,
      driverFaultCancellations: 1,
      passengerFaultCancellations: 2,
      completionRatePercent: 92,
    ),
  );

  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppSecondaryPage(
      title: 'Performance',
      onBack: onBack ?? () => context.pop(),
      maxWidth: AppLayout.pageMaxWidth,
      child: BlocBuilder<PerformanceCubit, PerformanceState>(
        builder: (context, state) => RefreshIndicator(
          color: context.colorScheme.onSurface,
          onRefresh:
              onRefresh ??
              () => BlocProvider.of<PerformanceCubit>(context).load(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? AppLayout.pagePadding
                  : AppLayout.pagePaddingWide;
              final hairline = Divider(
                height: 1,
                thickness: 1,
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.7,
                ),
              );
              final stats = state.stats;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.md,
                  horizontalPadding,
                  48,
                ),
                children: [
                  if (stats != null)
                    ..._buildStatsSections(stats, hairline)
                  else if (state.isLoading)
                    ExcludeSemantics(
                      child: Skeletonizer(
                        key: const ValueKey<String>(
                          'driver-performance-loading-skeleton',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildStatsSections(
                            _loadingStats,
                            hairline,
                          ),
                        ),
                      ),
                    )
                  else if (state.errorMessage case final errorMessage?)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxxl,
                      ),
                      child: AppRetryErrorView(
                        title: 'Unable to load performance',
                        message: errorMessage,
                        onRetry: () => unawaited(
                          BlocProvider.of<PerformanceCubit>(context).load(),
                        ),
                      ),
                    )
                  else
                    _buildEmptyState(context),
                  if (stats != null)
                    if (state.errorMessage case final errorMessage?) ...[
                      const SizedBox(height: AppSpacing.xl),
                      AppErrorBanner(
                        message: errorMessage,
                        onRetry: () => unawaited(
                          BlocProvider.of<PerformanceCubit>(context).load(),
                        ),
                        onDismiss: () =>
                            BlocProvider.of<PerformanceCubit>(context)
                                .dismissError(),
                      ),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStatsSections(PerformanceStats stats, Widget hairline) {
    final hasDistribution = stats.ratingDistribution.any((count) => count > 0);
    return [
      PerformanceSummarySection(stats: stats),
      const SizedBox(height: AppSpacing.xxl),
      hairline,
      const SizedBox(height: AppSpacing.xl),
      PerformanceMetricsSection(stats: stats),
      const SizedBox(height: AppSpacing.xl),
      hairline,
      const SizedBox(height: AppSpacing.xxl),
      PerformanceStandingSection(stats: stats),
      if (hasDistribution) ...[
        const SizedBox(height: AppSpacing.xxl),
        hairline,
        PerformanceRatingDistribution(stats: stats),
      ],
    ];
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.chart_no_axes_column,
                  size: 28,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No performance data yet',
                textAlign: TextAlign.center,
                style: textStyles.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Complete trips to see your rating and reliability summary.',
                textAlign: TextAlign.center,
                style: textStyles.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
