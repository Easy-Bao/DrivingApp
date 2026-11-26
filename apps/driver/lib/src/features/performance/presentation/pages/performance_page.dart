import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/performance/presentation/bloc/performance_cubit.dart';
import 'package:driver/src/features/performance/presentation/bloc/performance_state.dart';
import 'package:driver/src/features/performance/presentation/widgets/performance_sections.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';

class const PerformancePage({super.key, this.onBack, this.onRefresh})
    extends StatelessWidget {
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
              final hasDistribution =
                  stats?.ratingDistribution.any((count) => count > 0) ?? false;

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
                  if (state.isLoading) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (stats != null) ...[
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
                  ],
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
}
