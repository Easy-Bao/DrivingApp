import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

enum RideHistoryFilter { all, completed, cancelled }

class RideHistorySummary extends StatelessWidget {
  const RideHistorySummary({
    required this.weeklyFare,
    required this.weeklyRideCount,
    super.key,
  });

  final double weeklyFare;
  final int weeklyRideCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'This week',
                value: formatPesoAmount(weeklyFare),
                valueKey: const ValueKey<String>('activity-weekly-fare'),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
            Expanded(
              child: _SummaryMetric(
                label: 'Rides taken',
                value: weeklyRideCount.toString(),
                valueKey: const ValueKey<String>('activity-weekly-ride-count'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RideHistoryFilters extends StatelessWidget {
  const RideHistoryFilters({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });
  final RideHistoryFilter selectedFilter;
  final ValueChanged<RideHistoryFilter> onSelected;

  static const _tabs = RideHistoryFilter.values;

  double _indicatorAlignmentX(int index) {
    if (_tabs.length <= 1) return 0;
    return -1.0 + (2.0 * index / (_tabs.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final selectedIndex = _tabs.indexOf(selectedFilter);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              for (final filter in _tabs)
                Expanded(
                  child: _RideHistoryFilterTab(
                    filter: filter,
                    isSelected: filter == selectedFilter,
                    onTap: () => onSelected(filter),
                  ),
                ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedAlign(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment(_indicatorAlignmentX(selectedIndex), 1),
                child: FractionallySizedBox(
                  widthFactor: 1 / _tabs.length,
                  child: Container(height: 2, color: colors.onSurface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RideHistorySectionLabel extends StatelessWidget {
  const RideHistorySectionLabel({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label,
        style: context.textStyles.labelMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}

class RideHistoryFilteredEmpty extends StatelessWidget {
  const RideHistoryFilteredEmpty({required this.filter, super.key});
  final RideHistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final message = switch (filter) {
      RideHistoryFilter.all =>
        'Your completed and cancelled rides will appear here.',
      RideHistoryFilter.completed => 'No completed rides yet.',
      RideHistoryFilter.cancelled => 'No cancelled rides.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.route,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.valueKey,
  });
  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            key: valueKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleLarge?.tabular.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideHistoryFilterTab extends StatelessWidget {
  const _RideHistoryFilterTab({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });
  final RideHistoryFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label => switch (filter) {
    RideHistoryFilter.all => 'All',
    RideHistoryFilter.completed => 'Completed',
    RideHistoryFilter.cancelled => 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey<String>('activity-filter-${filter.name}'),
          onTap: onTap,
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSize.minimumTouchTarget,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  style:
                      (context.textStyles.labelLarge ??
                              DefaultTextStyle.of(context).style)
                          .copyWith(
                            color: isSelected
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                  child: Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
