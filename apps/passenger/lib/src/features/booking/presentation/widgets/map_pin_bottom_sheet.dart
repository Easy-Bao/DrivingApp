import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class MapPinBottomSheet extends StatelessWidget {
  const MapPinBottomSheet({
    super.key,
    required this.locationLabel,
    required this.confirmationLabel,
    required this.address,
    required this.subAddress,
    required this.isGeocoding,
    this.isLocatingCurrent = false,
    required this.onUseCurrentLocation,
    required this.onConfirm,
  });

  final String locationLabel;
  final String confirmationLabel;
  final String address;
  final String subAddress;
  final bool isGeocoding;
  final bool isLocatingCurrent;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textStyles = context.textStyles;

    return AppBottomSheetContainer(
      showShadow: true,
      backgroundColor: colors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppLayout.pagePadding,
        AppSpacing.sm + 2,
        AppLayout.pagePadding,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.map_pin,
                  color: colors.onSurface,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationLabel,
                      style: textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      address,
                      style: textStyles.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subAddress.isNotEmpty)
                      Text(
                        subAddress,
                        style: textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Semantics(
            button: true,
            label: isLocatingCurrent
                ? 'Locating current position'
                : 'Use my current location',
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
              onTap: isLocatingCurrent ? null : onUseCurrentLocation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSize.minimumTouchTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLocatingCurrent
                            ? 'Locating current position…'
                            : 'Use my current location',
                        style: textStyles.labelMedium?.copyWith(
                          color: isLocatingCurrent
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isLocatingCurrent)
                      SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    else
                      Icon(
                        LucideIcons.chevron_right,
                        color: colors.onSurfaceVariant,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: AppSize.controlHeight,
            child: FilledButton(
              onPressed: isGeocoding || isLocatingCurrent ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                disabledBackgroundColor: colors.primary.withValues(alpha: 0.45),
                disabledForegroundColor: colors.onPrimary.withValues(
                  alpha: 0.7,
                ),
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                isGeocoding ? 'Locating…' : confirmationLabel,
                style: textStyles.labelLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
