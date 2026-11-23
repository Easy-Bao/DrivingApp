import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardStatsRow extends StatelessWidget {
  const DashboardStatsRow({
    super.key,
    required this.isLoadingStats,
    required this.earnings,
    required this.completedTrips,
    this.hasExistingStats = false,
    this.hasError = false,
    this.errorMessage,
    this.onRetry,
  });

  final bool isLoadingStats;
  final double earnings;
  final int completedTrips;
  final bool hasExistingStats;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingStats && !hasExistingStats) {
      return _buildInitialLoadingState(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.pagePadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  label: "Today's Net Earnings",
                  value: hasError && !hasExistingStats
                      ? '—'
                      : formatPesoAmount(earnings),
                  icon: LucideIcons.wallet,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  context,
                  label: 'Trips Today',
                  value: hasError && !hasExistingStats
                      ? '—'
                      : '$completedTrips',
                  icon: LucideIcons.car,
                ),
              ),
            ],
          ),
        ),
        if (hasError) _buildErrorState(context),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppLayout.pagePadding,
        right: AppLayout.pagePadding,
        top: AppSpacing.xs,
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              LucideIcons.circle_alert,
              size: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Text(
              hasExistingStats
                  ? 'Showing last loaded stats.'
                  : (errorMessage ?? "Today's stats are unavailable."),
              style: context.textStyles.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton.icon(
            key: const ValueKey<String>('driver-dashboard-stats-retry'),
            onPressed: onRetry,
            style:
                TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return colorScheme.primary.withValues(alpha: 0.12);
                    }
                    return Colors.transparent;
                  }),
                ),
            icon: const Icon(LucideIcons.refresh_cw, size: 15),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall?.copyWith(
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ExcludeSemantics(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.headlineSmall?.tabular.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoadingState(BuildContext context) {
    return Skeletonizer.zone(
      key: const ValueKey<String>('driver-dashboard-stats-loading'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.pagePadding),
        child: Row(
          children: [
            Expanded(
              child: _buildInitialSkeletonCard(
                context,
                labelWidth: 94,
                valueWidth: 76,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildInitialSkeletonCard(
                context,
                labelWidth: 64,
                valueWidth: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialSkeletonCard(
    BuildContext context, {
    required double labelWidth,
    required double valueWidth,
  }) {
    final colorScheme = context.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Bone.text(width: labelWidth, fontSize: 11)),
              const SizedBox(width: AppSpacing.xs),
              const Bone.circle(size: 28),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Bone.text(width: valueWidth, fontSize: 22),
        ],
      ),
    );
  }
}
