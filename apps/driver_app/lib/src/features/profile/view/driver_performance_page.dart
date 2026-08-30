import 'dart:async';

import 'package:driver_app/src/features/profile/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverPerformancePage extends StatelessWidget {
  const DriverPerformancePage({super.key, this.onBack, this.onRefresh});

  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack ?? () => context.pop(),
          icon: const Icon(LucideIcons.arrow_left),
        ),
        title: const Text('Performance'),
        centerTitle: true,
      ),
      body: BlocBuilder<DriverAccountCubit, DriverAccountState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh:
              onRefresh ??
              () => BlocProvider.of<DriverAccountCubit>(context).load(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
                children: [
                  if (state.isLoading) const LinearProgressIndicator(),
                  if (state.isLoading) const SizedBox(height: 18),
                  _PerformanceSummary(account: state.account),
                  const SizedBox(height: 20),
                  _PerformanceMetrics(account: state.account),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    _PerformanceLoadNotice(
                      message: state.errorMessage!,
                      onRetry: () => unawaited(
                        BlocProvider.of<DriverAccountCubit>(context).load(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformanceSummary extends StatelessWidget {
  const _PerformanceSummary({required this.account});

  final DriverAccountSnapshot account;

  @override
  Widget build(BuildContext context) {
    final rating = account.averageRating > 0
        ? account.averageRating.toStringAsFixed(1)
        : account.ratingLabel;
    final completionRate = account.totalTrips == 0
        ? 0
        : (account.completedTrips / account.totalTrips * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.star,
            size: 28,
            color: context.colorScheme.onPrimary,
          ),
          const SizedBox(height: 10),
          Text(
            rating,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: context.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Driver rating',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onPrimary.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: context.colorScheme.onPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$completionRate% trip completion',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetrics extends StatelessWidget {
  const _PerformanceMetrics({required this.account});

  final DriverAccountSnapshot account;

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
              value: '${account.completedTrips}',
            ),
            _PerformanceMetricCard(
              width: cardWidth,
              icon: LucideIcons.route,
              label: 'Total trips',
              value: '${account.totalTrips}',
            ),
            _PerformanceMetricCard(
              width: constraints.maxWidth,
              icon: LucideIcons.wallet_cards,
              label: 'Lifetime earnings',
              value: formatPesoAmount(account.lifetimeEarnings),
            ),
          ],
        );
      },
    );
  }
}

class _PerformanceMetricCard extends StatelessWidget {
  const _PerformanceMetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceLoadNotice extends StatelessWidget {
  const _PerformanceLoadNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circle_alert,
            color: context.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
