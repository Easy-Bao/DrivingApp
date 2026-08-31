import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/domain/saved_place_defaults.dart';
import 'package:passenger_app/src/features/saved_places/presentation/saved_place_icon.dart';
import 'package:shared_ui/shared_ui.dart';

class SavedPlaceQuickActionsWidget extends StatelessWidget {
  final List<SavedPlace> places;
  final ValueChanged<SavedPlace> onPlaceTap;
  final ValueChanged<SavedPlace>? onPlaceLongPress;
  final VoidCallback onAddPlace;

  const SavedPlaceQuickActionsWidget({
    required this.places,
    required this.onPlaceTap,
    required this.onAddPlace,
    this.onPlaceLongPress,
    super.key,
  });

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
            GestureDetector(
              onTap: () => onPlaceTap(orderedPlaces[index]),
              onLongPress: onPlaceLongPress == null
                  ? null
                  : () => onPlaceLongPress!(orderedPlaces[index]),
              child: _SavedPlaceChip(
                place: orderedPlaces[index],
                isActive: index == 0 && defaultIndex >= 0,
              ),
            ),
            const SizedBox(width: 10),
          ],
          _AddPlaceChip(onTap: onAddPlace),
        ],
      ),
    );
  }
}

class _SavedPlaceChip extends StatelessWidget {
  final SavedPlace place;
  final bool isActive;

  const _SavedPlaceChip({required this.place, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final showActiveStyle = isActive && place.hasLocation;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: showActiveStyle
            ? context.colorScheme.primary
            : context.colorScheme.surface,
        border: Border.all(
          color: showActiveStyle
              ? context.colorScheme.primary
              : context.colorScheme.outlineVariant,
          width: showActiveStyle ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            savedPlaceIconFromName(place.iconName),
            size: 16,
            color: showActiveStyle
                ? context.colorScheme.onPrimary
                : context.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            place.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: showActiveStyle
                  ? context.colorScheme.onPrimary
                  : context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPlaceChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPlaceChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.surface.withValues(alpha: 0),
          border: Border.all(
            color: context.colorScheme.onSurface.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.plus,
              size: 16,
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Add place',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
