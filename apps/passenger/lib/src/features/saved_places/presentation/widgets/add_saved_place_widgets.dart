import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const SavedPlaceIconOption({
  required this.name,
  required this.label,
  required this.icon,
}) {
  final String name;
  final String label;
  final IconData icon;
}

const List<SavedPlaceIconOption> savedPlaceIconOptions = <SavedPlaceIconOption>[
  SavedPlaceIconOption(
    name: 'heart',
    label: 'Favorite',
    icon: LucideIcons.heart,
  ),
  SavedPlaceIconOption(name: 'users', label: 'Family', icon: LucideIcons.users),
  SavedPlaceIconOption(
    name: 'graduation_cap',
    label: 'School',
    icon: LucideIcons.graduation_cap,
  ),
  SavedPlaceIconOption(name: 'store', label: 'Store', icon: LucideIcons.store),
  SavedPlaceIconOption(name: 'star', label: 'Starred', icon: LucideIcons.star),
  SavedPlaceIconOption(
    name: 'map_pin',
    label: 'Pinned place',
    icon: LucideIcons.map_pin,
  ),
  SavedPlaceIconOption(name: 'house', label: 'Home', icon: LucideIcons.house),
  SavedPlaceIconOption(
    name: 'briefcase',
    label: 'Work',
    icon: LucideIcons.briefcase,
  ),
];

class SavedPlaceFieldLabel extends StatelessWidget {
  const SavedPlaceFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.textStyles.labelSmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.85,
      ),
    );
  }
}

class SavedPlaceLocationCard extends StatelessWidget {
  const SavedPlaceLocationCard({
    super.key,
    required this.addressLabel,
    required this.isLocationPinned,
  });

  final String addressLabel;
  final bool isLocationPinned;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: Icon(
                LucideIcons.map_pin,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              addressLabel,
              style: context.textStyles.bodyMedium?.copyWith(
                color: isLocationPinned
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedPlaceIconPicker extends StatelessWidget {
  const SavedPlaceIconPicker({
    super.key,
    required this.selectedIcon,
    required this.animationDuration,
    required this.onSelected,
  });

  final IconData selectedIcon;
  final Duration animationDuration;
  final ValueChanged<IconData> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final option in savedPlaceIconOptions)
          Semantics(
            button: true,
            selected: selectedIcon == option.icon,
            label: option.label,
            child: InkWell(
              key: ValueKey<String>('add-place-icon-${option.name}'),
              onTap: () => onSelected(option.icon),
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return colorScheme.primary.withValues(alpha: 0.14);
                }
                return Colors.transparent;
              }),
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                width: AppSize.minimumTouchTarget,
                height: AppSize.minimumTouchTarget,
                decoration: BoxDecoration(
                  color: selectedIcon == option.icon
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedIcon == option.icon
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  option.icon,
                  color: selectedIcon == option.icon
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SavedPlaceLocationUnavailableView extends StatelessWidget {
  const SavedPlaceLocationUnavailableView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.map_pin_off,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Location unavailable',
              style: textStyles.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
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
      ),
    );
  }
}
