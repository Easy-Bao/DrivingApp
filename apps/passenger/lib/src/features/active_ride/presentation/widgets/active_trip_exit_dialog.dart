import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

enum ActiveTripExitAction { keepTracking, minimize, cancel }

class const ActiveTripExitDialog({
  required this.driverName,
  this.canCancel = true,
  super.key,
}) extends StatelessWidget {
  final String driverName;
  final bool canCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return AlertDialog(
      backgroundColor: colors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colors.outlineVariant),
      ),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: colors.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Icon(LucideIcons.navigation, size: 20, color: colors.onSurface),
      ),
      title: Text(
        'Trip in progress',
        textAlign: TextAlign.center,
        style: context.textStyles.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      content: Text(
        'You have an ongoing ride with $driverName.\n\nWhat would you like to do?',
        textAlign: TextAlign.center,
        style: context.textStyles.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
          height: 1.45,
        ),
      ),
      actions: [
        if (canCancel)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, ActiveTripExitAction.cancel),
            style:
                TextButton.styleFrom(
                  foregroundColor: colors.error,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size(0, AppSize.minimumTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: context.textStyles.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? colors.error.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                ),
            child: const Text('Cancel ride'),
          ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, ActiveTripExitAction.minimize),
          style:
              TextButton.styleFrom(
                foregroundColor: colors.onSurface,
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                minimumSize: const Size(0, AppSize.minimumTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? colors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
              ),
          child: const Text('Go to home'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, ActiveTripExitAction.keepTracking),
          style:
              FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                elevation: 0,
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                minimumSize: const Size(0, AppSize.minimumTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? colors.onPrimary.withValues(alpha: 0.16)
                      : Colors.transparent,
                ),
              ),
          child: const Text('Keep tracking'),
        ),
      ],
    );
  }
}
