import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

enum PassengerActivityFilter { all, completed, cancelled }

class PassengerActivitySummaryWidget extends StatelessWidget {
  final double weeklyFare;
  final int weeklyRideCount;

  const PassengerActivitySummaryWidget({
    required this.weeklyFare,
    required this.weeklyRideCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'This week',
            value: '₱${weeklyFare.toStringAsFixed(2)}',
            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.55),
            valueKey: const ValueKey<String>('activity-weekly-fare'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Rides taken',
            value: weeklyRideCount.toString(),
            backgroundColor: AppTheme.neutralColor,
            valueKey: const ValueKey<String>('activity-weekly-ride-count'),
          ),
        ),
      ],
    );
  }
}

class PassengerActivityFiltersWidget extends StatelessWidget {
  final PassengerActivityFilter selectedFilter;
  final ValueChanged<PassengerActivityFilter> onSelected;

  const PassengerActivityFiltersWidget({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in PassengerActivityFilter.values)
          _ActivityFilterChip(
            filter: filter,
            isSelected: filter == selectedFilter,
            onTap: () => onSelected(filter),
          ),
      ],
    );
  }
}

class PassengerActivitySectionLabel extends StatelessWidget {
  final String label;

  const PassengerActivitySectionLabel({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.tertiaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class PassengerActivityFilteredEmptyWidget extends StatelessWidget {
  final PassengerActivityFilter filter;

  const PassengerActivityFilteredEmptyWidget({required this.filter, super.key});

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      PassengerActivityFilter.all =>
        'Your completed and cancelled rides will appear here.',
      PassengerActivityFilter.completed => 'No completed rides yet.',
      PassengerActivityFilter.cancelled => 'No cancelled rides.',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 112),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.route,
            size: 34,
            color: AppTheme.tertiaryColor.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.tertiaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Key valueKey;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.tertiaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            key: valueKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFilterChip extends StatelessWidget {
  final PassengerActivityFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityFilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  String get _label => switch (filter) {
    PassengerActivityFilter.all => 'All',
    PassengerActivityFilter.completed => 'Completed',
    PassengerActivityFilter.cancelled => 'Cancelled',
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.surface,
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderSide,
              ),
            ),
            child: Text(
              _label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? AppTheme.surface : AppTheme.tertiaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
