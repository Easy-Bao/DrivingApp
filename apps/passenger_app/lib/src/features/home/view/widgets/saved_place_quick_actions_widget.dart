import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/domain/saved_place_defaults.dart';
import 'package:passenger_app/src/features/saved_places/view/saved_place_icon.dart';

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
    final defaultPlace = defaultSavedPlace(places);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          if (defaultPlace != null) ...[
            GestureDetector(
              onTap: () => onPlaceTap(defaultPlace),
              onLongPress: onPlaceLongPress == null
                  ? null
                  : () => onPlaceLongPress!(defaultPlace),
              child: _SavedPlaceChip(place: defaultPlace),
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

  const _SavedPlaceChip({required this.place});

  @override
  Widget build(BuildContext context) {
    final hasLocation = place.hasLocation;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: hasLocation
            ? AppTheme.activeControlBackground
            : AppTheme.interactiveSurface,
        border: Border.all(
          color: hasLocation
              ? AppTheme.activeControlBackground
              : AppTheme.borderSide,
          width: hasLocation ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            savedPlaceIconFromName(place.iconName),
            size: 16,
            color: hasLocation
                ? AppTheme.activeControlForeground
                : AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            place.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: hasLocation
                  ? AppTheme.activeControlForeground
                  : AppTheme.primaryColor,
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
          color: AppTheme.surface.withValues(alpha: 0),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.plus,
              size: 16,
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Add place',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
