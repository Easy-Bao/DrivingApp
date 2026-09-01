import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

enum TripHistoryFilter { all, completed, cancelled }

Future<TripHistoryFilter?> showTripHistoryFilterSheet({
  required BuildContext context,
  required TripHistoryFilter selectedFilter,
}) {
  final overlayBox =
      Overlay.of(context).context.findRenderObject() as RenderBox;
  final mediaQuery = MediaQuery.of(context);
  final menuWidth = math.min(340.0, overlayBox.size.width - 24.0);
  final left = math.max(12.0, overlayBox.size.width - menuWidth - 12.0);
  return showMenu<TripHistoryFilter>(
    context: context,
    position: RelativeRect.fromLTRB(
      left,
      mediaQuery.padding.top + kToolbarHeight - 4,
      12,
      math.max(12.0, overlayBox.size.height - mediaQuery.padding.top - 60),
    ),
    constraints: BoxConstraints.tightFor(width: menuWidth),
    color: Theme.of(context).colorScheme.surface,
    elevation: 10,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    items: [
      PopupMenuItem<TripHistoryFilter>(
        enabled: false,
        height: 68,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: _FilterMenuHeader(),
      ),
      for (final filter in TripHistoryFilter.values)
        PopupMenuItem<TripHistoryFilter>(
          value: filter,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: _FilterMenuOption(
            filter: filter,
            selectedFilter: selectedFilter,
          ),
        ),
    ],
  );
}

class const TripHistoryFilterSheet({super.key, required this.selectedFilter})
    extends StatelessWidget {
  final TripHistoryFilter selectedFilter;

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
                          color: colors.onSurfaceVariant,
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

class _FilterMenuHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
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
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class const _FilterMenuOption({
  required this.filter,
  required this.selectedFilter,
}) extends StatelessWidget {
  final TripHistoryFilter filter;
  final TripHistoryFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = filter == selectedFilter;
    final title = switch (filter) {
      TripHistoryFilter.all => 'All Trips',
      TripHistoryFilter.completed => 'Completed Trips',
      TripHistoryFilter.cancelled => 'Cancelled Trips',
    };
    final description = switch (filter) {
      TripHistoryFilter.all => 'Completed and cancelled trips',
      TripHistoryFilter.completed => 'Trips that reached the destination',
      TripHistoryFilter.cancelled => 'Trips cancelled before completion',
    };
    final icon = switch (filter) {
      TripHistoryFilter.all => LucideIcons.list,
      TripHistoryFilter.completed => LucideIcons.circle_check,
      TripHistoryFilter.cancelled => LucideIcons.circle_x,
    };
    final foreground = selected ? colors.onPrimary : colors.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 17, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? colors.onPrimary.withValues(alpha: 0.84)
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? LucideIcons.check : LucideIcons.chevron_right,
              size: 16,
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class const _FilterOption({
  required this.filter,
  required this.selectedFilter,
  required this.icon,
  required this.title,
  required this.description,
}) extends StatelessWidget {
  final TripHistoryFilter filter;
  final TripHistoryFilter selectedFilter;
  final IconData icon;
  final String title;
  final String description;

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
                        fontSize: 12,
                        color: isSelected
                            ? colors.onPrimary.withValues(alpha: 0.84)
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? LucideIcons.check : LucideIcons.chevron_right,
                size: 17,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
