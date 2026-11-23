import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_trip_card.dart';

class FindingDriverStatusSheet extends StatelessWidget {
  const FindingDriverStatusSheet({
    super.key,
    required this.title,
    required this.message,
    required this.statusIcon,
    required this.statusColor,
    required this.destination,
    this.pickupAddress,

    required this.fare,
    required this.onCancelPressed,
    this.primaryAction,
    this.primaryActionLabel,
    this.cancelLabel = 'Cancel search',
    this.isCanceling = false,
  });

  final String title;
  final String message;
  final IconData statusIcon;
  final Color statusColor;
  final String destination;
  final String? pickupAddress;

  final double fare;
  final VoidCallback onCancelPressed;
  final VoidCallback? primaryAction;
  final String? primaryActionLabel;
  final String cancelLabel;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Material(
      key: const ValueKey('finding-driver-status-sheet'),
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: colors.onSurface.withValues(alpha: 0.08),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.pagePadding,
              AppSpacing.md,
              AppLayout.pagePadding,
              AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceContainerLowest,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(statusIcon, color: statusColor, size: 22),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                FindingDriverTripCard(
                  key: const ValueKey('finding-driver-trip-context'),
                  pickup: pickupAddress?.trim().isNotEmpty == true
                      ? pickupAddress!.trim()
                      : 'Current location',
                  destination: destination,
                  fare: fare,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (primaryAction != null && primaryActionLabel != null)
                  FilledButton(
                    onPressed: isCanceling ? null : primaryAction,
                    style:
                        FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          elevation: 0,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size.fromHeight(
                            AppSize.controlHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    child: Text(primaryActionLabel!),
                  ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: isCanceling ? null : onCancelPressed,
                  style:
                      TextButton.styleFrom(
                        foregroundColor: colors.onSurfaceVariant,
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        minimumSize: const Size.fromHeight(
                          AppSize.minimumTouchTarget,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? colors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                        ),
                      ),
                  child: isCanceling
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onSurface,
                          ),
                        )
                      : Text(cancelLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
