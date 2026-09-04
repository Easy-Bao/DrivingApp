import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';

enum RideHistoryFilter { all, completed, cancelled }

class const RideHistorySummaryWidget({
  required this.weeklyFare,
  required this.weeklyRideCount,
  super.key,
}) extends StatelessWidget {
  final double weeklyFare;
  final int weeklyRideCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'This week',
            value: formatPesoAmount(weeklyFare),
            backgroundColor: context.colorScheme.secondaryContainer.withValues(
              alpha: 0.55,
            ),
            valueKey: const ValueKey<String>('activity-weekly-fare'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Rides taken',
            value: weeklyRideCount.toString(),
            backgroundColor: context.colorScheme.surfaceContainerHighest,
            valueKey: const ValueKey<String>('activity-weekly-ride-count'),
          ),
        ),
      ],
    );
  }
}

class const RideHistoryFiltersWidget({
  required this.selectedFilter,
  required this.onSelected,
  super.key,
}) extends StatelessWidget {
  final RideHistoryFilter selectedFilter;
  final ValueChanged<RideHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in RideHistoryFilter.values)
          _RideHistoryFilterChip(
            filter: filter,
            isSelected: filter == selectedFilter,
            onTap: () => onSelected(filter),
          ),
      ],
    );
  }
}

class const RideHistorySectionLabel({required this.label, super.key})
    extends StatelessWidget {
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class const RideHistoryFilteredEmptyWidget({required this.filter, super.key})
    extends StatelessWidget {
  final RideHistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      RideHistoryFilter.all =>
        'Your completed and cancelled rides will appear here.',
      RideHistoryFilter.completed => 'No completed rides yet.',
      RideHistoryFilter.cancelled => 'No cancelled rides.',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 112),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.route,
            size: 34,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class const _SummaryCard({
  required this.label,
  required this.value,
  required this.backgroundColor,
  required this.valueKey,
}) extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            key: valueKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class const _RideHistoryFilterChip({
  required this.filter,
  required this.isSelected,
  required this.onTap,
}) extends StatelessWidget {
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
    final radius = BorderRadius.circular(22);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey<String>('activity-filter-${filter.name}'),
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colorScheme.onSurface
                  : context.colorScheme.surface,
              borderRadius: radius,
              border: Border.all(
                color: isSelected
                    ? context.colorScheme.onSurface
                    : context.colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              _label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? context.colorScheme.surface
                    : context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
