import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';

class const FindingDriverNearestPanel({
  super.key,
  required this.state,
  required this.fare,
  required this.onViewFullProfilePressed,
  required this.onBookDirectPressed,
  required this.onSearchAllDriversPressed,
  required this.onCancelRidePressed,
  this.isCanceling = false,
}) extends StatelessWidget {
  final NearestDriverFound state;
  final double fare;
  final VoidCallback onViewFullProfilePressed;
  final VoidCallback onBookDirectPressed;
  final VoidCallback onSearchAllDriversPressed;
  final VoidCallback onCancelRidePressed;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final driver = state.driver;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.pagePadding,
          10,
          AppLayout.pagePadding,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          border: Border(top: BorderSide(color: colors.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: colors.onSurface.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.user_round,
                    color: colors.onSurface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearest Driver',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        driver.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        driver.vehicleSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPesoAmount(fare),
                      style: context.textStyles.titleMedium?.tabular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Estimated Fare',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            Row(
              children: [
                _metric(
                  context,
                  icon: Icons.star_rounded,
                  label: '${driver.rating.toStringAsFixed(1)} Rating',
                  color: context.semanticColors.rating,
                ),
                const SizedBox(width: AppSpacing.sm),
                _metric(
                  context,
                  icon: LucideIcons.navigation,
                  label:
                      '${DistanceFormatter.fromKilometers(driver.distanceKm)} Away',
                ),
                const SizedBox(width: AppSpacing.sm),
                _metric(
                  context,
                  icon: driver.hasPassengerOnboard
                      ? LucideIcons.users
                      : LucideIcons.user_check,
                  label: driver.hasPassengerOnboard ? 'On Trip' : 'Available',
                  color: driver.hasPassengerOnboard
                      ? context.semanticColors.warning
                      : context.semanticColors.success,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewFullProfilePressed,
                    style:
                        OutlinedButton.styleFrom(
                          backgroundColor: colors.surfaceContainerLowest,
                          foregroundColor: colors.onSurface,
                          side: BorderSide(color: colors.outlineVariant),
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size(0, AppSize.controlHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    child: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onBookDirectPressed,
                    style:
                        FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          elevation: 0,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size(0, AppSize.controlHeight),
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
                    child: const Text('Choose Driver'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onSearchAllDriversPressed,
                    style:
                        TextButton.styleFrom(
                          foregroundColor: colors.onSurfaceVariant,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size(
                            0,
                            AppSize.minimumTouchTarget,
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? colors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                        ),
                    child: const Text('Compare All Drivers'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: isCanceling ? null : onCancelRidePressed,
                    style:
                        TextButton.styleFrom(
                          foregroundColor: colors.error,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size(
                            0,
                            AppSize.minimumTouchTarget,
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? colors.error.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                        ),
                    child: isCanceling
                        ? SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.error,
                            ),
                          )
                        : const Text('Cancel Ride'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final resolvedColor = color ?? context.colorScheme.onSurface;
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: resolvedColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall?.tabular.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
