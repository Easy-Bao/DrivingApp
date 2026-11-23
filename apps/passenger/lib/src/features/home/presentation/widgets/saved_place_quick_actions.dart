import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place_defaults.dart';
import 'package:passenger/src/features/saved_places/presentation/widgets/saved_place_icon.dart';

class SavedPlaceQuickActions extends StatelessWidget {
  const SavedPlaceQuickActions({
    required this.places,
    required this.onPlaceTap,
    required this.onAddPlace,
    this.onPlaceLongPress,
    super.key,
  });

  final List<SavedPlace> places;
  final ValueChanged<SavedPlace> onPlaceTap;
  final ValueChanged<SavedPlace>? onPlaceLongPress;
  final VoidCallback onAddPlace;

  @override
  Widget build(BuildContext context) {
    final defaultIndex = defaultSavedPlaceIndex(places);
    final orderedPlaces = [
      if (defaultIndex >= 0) places[defaultIndex],
      for (var index = 0; index < places.length; index++)
        if (index != defaultIndex) places[index],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < orderedPlaces.length; index++) ...[
            Semantics(
              button: true,
              selected: index == 0 && defaultIndex >= 0,
              label: 'Saved place ${orderedPlaces[index].label}',
              hint: onPlaceLongPress == null
                  ? 'Sets this as your destination'
                  : 'Sets this as your destination. Long press for options',
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? context.colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                  onTap: () => onPlaceTap(orderedPlaces[index]),
                  onLongPress: onPlaceLongPress == null
                      ? null
                      : () => onPlaceLongPress!(orderedPlaces[index]),
                  child: _SavedPlaceChip(
                    place: orderedPlaces[index],
                    isActive: index == 0 && defaultIndex >= 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          _AddPlaceChip(onTap: onAddPlace),
        ],
      ),
    );
  }
}

class _SavedPlaceChip extends StatelessWidget {
  const _SavedPlaceChip({required this.place, required this.isActive});
  static const _maximumLabelWidth = 180.0;

  final SavedPlace place;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final showActiveStyle = isActive && place.hasLocation;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: AppSize.minimumTouchTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: showActiveStyle ? colors.primary : colors.surface,
        border: Border.all(
          color: showActiveStyle ? colors.primary : colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            savedPlaceIconFromName(place.iconName),
            size: 15,
            color: showActiveStyle ? colors.onPrimary : colors.onSurface,
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maximumLabelWidth),
            child: Text(
              place.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: showActiveStyle ? colors.onPrimary : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPlaceChip extends StatelessWidget {
  const _AddPlaceChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Semantics(
      button: true,
      label: 'Add saved place',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? colors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSize.minimumTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.plus,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add place',
                  style: context.textStyles.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
