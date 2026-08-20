import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

enum TripHistoryFilter { all, completed, cancelled }

Future<TripHistoryFilter?> showTripHistoryFilterSheet({
  required BuildContext context,
  required TripHistoryFilter selectedFilter,
}) {
  return showModalBottomSheet<TripHistoryFilter>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TripHistoryFilterSheet(selectedFilter: selectedFilter),
  );
}

class TripHistoryFilterSheet extends StatelessWidget {
  final TripHistoryFilter selectedFilter;

  const TripHistoryFilterSheet({
    super.key,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.list_filter,
                    size: 18,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Trips',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose which trips appear in your history.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _FilterOption(
              filter: TripHistoryFilter.all,
              selectedFilter: selectedFilter,
              icon: LucideIcons.list,
              title: 'All Trips',
              description: 'Completed and cancelled trips',
            ),
            const SizedBox(height: 8),
            _FilterOption(
              filter: TripHistoryFilter.completed,
              selectedFilter: selectedFilter,
              icon: LucideIcons.circle_check,
              title: 'Completed Trips',
              description: 'Trips that reached the destination',
            ),
            const SizedBox(height: 8),
            _FilterOption(
              filter: TripHistoryFilter.cancelled,
              selectedFilter: selectedFilter,
              icon: LucideIcons.circle_x,
              title: 'Cancelled Trips',
              description: 'Trips cancelled before completion',
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final TripHistoryFilter filter;
  final TripHistoryFilter selectedFilter;
  final IconData icon;
  final String title;
  final String description;

  const _FilterOption({
    required this.filter,
    required this.selectedFilter,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = filter == selectedFilter;
    final foreground = isSelected ? colors.onPrimary : colors.onSurface;
    return Material(
      color: isSelected
          ? colors.primary
          : colors.onSurface.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pop(filter),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: foreground.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? LucideIcons.check : LucideIcons.chevron_right,
                size: 17,
                color: foreground.withValues(alpha: isSelected ? 1 : 0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
