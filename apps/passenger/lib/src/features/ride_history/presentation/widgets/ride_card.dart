import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/ride_history/presentation/formatters/ride_history_presenter.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

class ActiveRideCard extends StatelessWidget {
  const ActiveRideCard({
    required this.ride,
    required this.presenter,
    required this.onTap,
    super.key,
  });
  final RideHistory ride;
  final RideHistoryPresenter presenter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final status = RideStatus.fromString(ride.status);
    final destination = presenter.destinationLabel(ride);
    final statusLabel = switch (status) {
      RideStatus.requested => 'Finding a driver',
      RideStatus.accepted => 'Driver confirmed',
      RideStatus.arrived => 'Driver has arrived',
      RideStatus.inTransit => 'Trip in progress',
      _ => 'Active ride',
    };

    return Semantics(
      button: true,
      label: '$statusLabel to $destination',
      child: Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('active-ride-${ride.id}'),
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.navigation,
                        size: 16,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: context.textStyles.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      presenter.fareLabel(ride),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleMedium?.tabular.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      LucideIcons.chevron_right,
                      color: colors.onSurfaceVariant,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (ride.pickup.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'From ${ride.pickup.trim()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PastRideCard extends StatelessWidget {
  const PastRideCard({
    required this.ride,
    required this.presenter,
    required this.onTap,
    super.key,
  });
  final RideHistory ride;
  final RideHistoryPresenter presenter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final status = RideStatus.fromString(ride.status);
    final isCancelled = status == RideStatus.cancelled;
    final statusLabel = isCancelled ? 'Cancelled' : 'Completed';
    final statusColor = isCancelled
        ? colors.error
        : context.semanticColors.success;
    final destination = presenter.destinationLabel(ride);
    final metadata = presenter.rideMetadata(ride);

    return Semantics(
      button: true,
      label: '$statusLabel ride to $destination',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey<String>('past-ride-${ride.id}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCancelled
                            ? colors.error.withValues(alpha: 0.35)
                            : colors.outlineVariant,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isCancelled ? LucideIcons.x : LucideIcons.check,
                      color: statusColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (metadata.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            metadata,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodySmall?.tabular
                                .copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 88),
                    child: Text(
                      presenter.fareLabel(ride),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: context.textStyles.titleSmall?.tabular.copyWith(
                        color: isCancelled
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
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
      ),
    );
  }
}
