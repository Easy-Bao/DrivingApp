import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:design_system/src/widgets/layout/bottom_sheet_container.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

enum TripHistoryFilter { all, completed, cancelled }

Future<TripHistoryFilter?> showTripHistoryFilterSheet({
  required BuildContext context,
  required TripHistoryFilter selectedFilter,
}) {
  return showModalBottomSheet<TripHistoryFilter>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TripHistoryFilterSheet(selectedFilter: selectedFilter),
  );
}

class const TripHistoryFilterSheet({super.key, required this.selectedFilter})
    extends StatelessWidget {
  final TripHistoryFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppBottomSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
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
              const SizedBox(width: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.lg + 2),
          _FilterOption(
            filter: TripHistoryFilter.all,
            selectedFilter: selectedFilter,
            icon: LucideIcons.list,
            title: 'All Trips',
            description: 'Completed and cancelled trips',
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterOption(
            filter: TripHistoryFilter.completed,
            selectedFilter: selectedFilter,
            icon: LucideIcons.circle_check,
            title: 'Completed Trips',
            description: 'Trips that reached the destination',
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterOption(
            filter: TripHistoryFilter.cancelled,
            selectedFilter: selectedFilter,
            icon: LucideIcons.circle_x,
            title: 'Cancelled Trips',
            description: 'Trips cancelled before completion',
          ),
        ],
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
    final colors = context.colorScheme;
    final textStyles = context.textStyles;
    final isSelected = filter == selectedFilter;
    final foreground = isSelected ? colors.onPrimary : colors.onSurface;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $description',
      child: Material(
        color: isSelected
            ? colors.primary
            : colors.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => Navigator.of(context).pop(filter),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSize.minimumTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, size: 18, color: foreground),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textStyles.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          description,
                          style: textStyles.bodySmall?.copyWith(
                            color: isSelected
                                ? colors.onPrimary.withValues(alpha: 0.84)
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      isSelected
                          ? LucideIcons.check
                          : LucideIcons.chevron_right,
                      size: 17,
                      color: isSelected
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
