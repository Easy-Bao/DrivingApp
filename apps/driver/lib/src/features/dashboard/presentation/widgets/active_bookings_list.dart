import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class ActiveBookingsList extends StatelessWidget {
  const ActiveBookingsList({
    super.key,
    required this.rides,
    required this.onOpen,
    this.openingRideId,
    this.errorMessage,
    this.onRetry,
  });

  final List<RideSnapshot> rides;
  final ValueChanged<String> onOpen;
  final String? openingRideId;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final hairlineColor = colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              '${rides.length} / ${DashboardState.maxActiveBookings} active bookings',
              style: textStyles.titleMedium?.tabular.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Open a booking to manage pickup or drop-off.',
            style: textStyles.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      LucideIcons.circle_alert,
                      size: 16,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: textStyles.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    style:
                        TextButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.focused)) {
                              return colorScheme.primary.withValues(
                                alpha: 0.12,
                              );
                            }
                            return Colors.transparent;
                          }),
                        ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: hairlineColor),
          for (var index = 0; index < rides.length; index++) ...[
            _ActiveBookingRow(
              ride: rides[index],
              isOpening: openingRideId == rides[index].id,
              onTap: openingRideId == null
                  ? () => onOpen(rides[index].id)
                  : null,
            ),
            if (index != rides.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 54,
                color: colorScheme.outlineVariant.withValues(alpha: 0.65),
              ),
          ],
          Divider(height: 1, thickness: 1, color: hairlineColor),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class const _ActiveBookingRow({
  required this.ride,
  required this.isOpening,
  required this.onTap,
}) extends StatelessWidget {
  final RideSnapshot ride;
  final bool isOpening;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final isInTransit = ride.status == 'in_transit';
    final statusLabel = switch (ride.status) {
      'in_transit' => 'Onboard',
      'arrived' => 'Waiting at pickup',
      _ => 'Awaiting pickup',
    };
    final destination = isInTransit ? ride.dropoffName : ride.pickupName;
    final passengerName = ride.passengerName ?? 'Passenger';

    return Semantics(
      button: true,
      label: '$passengerName. $statusLabel. $destination',
      child: InkWell(
        key: ValueKey<String>('driver-active-booking-${ride.id}'),
        onTap: onTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.minimumTouchTarget + 20,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isInTransit
                          ? context.semanticColors.success.withValues(
                              alpha: 0.08,
                            )
                          : colorScheme.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isInTransit
                            ? context.semanticColors.success.withValues(
                                alpha: 0.35,
                              )
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isInTransit
                          ? LucideIcons.navigation
                          : LucideIcons.map_pin,
                      size: 17,
                      color: isInTransit
                          ? context.semanticColors.success
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passengerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$statusLabel\n$destination',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (isOpening)
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurface,
                    ),
                  )
                else
                  ExcludeSemantics(
                    child: Icon(
                      LucideIcons.chevron_right,
                      size: 17,
                      color: colorScheme.onSurfaceVariant,
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
