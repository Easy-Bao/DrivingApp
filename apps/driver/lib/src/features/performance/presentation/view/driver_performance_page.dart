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

class const DriverPerformancePage({super.key, this.onBack, this.onRefresh})
    extends StatelessWidget {
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return EasyRideSecondaryPage(
      title: 'Performance',
      onBack: onBack ?? () => context.pop(),
      child: BlocBuilder<DriverPerformanceCubit, DriverPerformanceState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh:
              onRefresh ??
              () => BlocProvider.of<DriverPerformanceCubit>(context).load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              EasyRideLayout.pagePadding,
              EasyRideLayout.pagePadding,
              EasyRideLayout.pagePadding,
              48,
            ),
            children: [
              if (state.isLoading) const LinearProgressIndicator(),
              if (state.isLoading) const SizedBox(height: 18),
              _PerformanceSummary(stats: state.stats),
              const SizedBox(height: 20),
              _PerformanceMetrics(stats: state.stats),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 20),
                AppErrorBanner(
                  message: state.errorMessage!,
                  onRetry: () => unawaited(
                    BlocProvider.of<DriverPerformanceCubit>(context).load(),
                  ),
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
  final DriverPerformanceStats? stats;

  @override
  Widget build(BuildContext context) {
    final rating = stats?.averageRating != null && stats!.averageRating > 0
        ? stats!.averageRating.toStringAsFixed(1)
        : '—';
    final totalTrips = stats?.totalTrips ?? 0;
    final completedTrips = stats?.completedTrips ?? 0;
    final completionRate = totalTrips == 0
        ? 0
        : (completedTrips / totalTrips * 100).round();

    return Container(
      padding: const EdgeInsets.all(EasyRideSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.star,
            size: 28,
            color: context.semanticColors.rating,
          ),
          const SizedBox(height: 10),
          Text(
            rating,
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(color: context.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 4),
          Text(
            'Driver rating',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.76,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: context.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(EasyRideRadius.pill),
            ),
            child: Text(
              '$completionRate% trip completion',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: context.colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class const _PerformanceMetrics({required this.stats}) extends StatelessWidget {
  final DriverPerformanceStats? stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 340;
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
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(EasyRideSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: context.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
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
