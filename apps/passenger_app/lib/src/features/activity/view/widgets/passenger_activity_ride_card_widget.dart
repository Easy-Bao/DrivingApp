import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/activity/view/widgets/passenger_activity_history_presenter.dart';
import 'package:shared_core/shared_core.dart';

class PassengerActiveRideCardWidget extends StatelessWidget {
  final RideHistoryModel ride;
  final PassengerActivityHistoryPresenter presenter;
  final VoidCallback onTap;

  const PassengerActiveRideCardWidget({
    required this.ride,
    required this.presenter,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.borderSide),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('active-ride-${ride.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.navigation,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      presenter.fareLabel(ride),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevron_right,
                      color: AppTheme.tertiaryColor,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (ride.pickup.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'From ${ride.pickup.trim()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.tertiaryColor,
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

class PassengerPastRideCardWidget extends StatelessWidget {
  final RideHistoryModel ride;
  final PassengerActivityHistoryPresenter presenter;
  final VoidCallback onTap;

  const PassengerPastRideCardWidget({
    required this.ride,
    required this.presenter,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final status = RideStatus.fromString(ride.status);
    final isCancelled = status == RideStatus.cancelled;
    final statusLabel = isCancelled ? 'Cancelled' : 'Completed';
    final statusColor = isCancelled ? AppTheme.cancel : AppTheme.complete;
    final destination = presenter.destinationLabel(ride);
    final metadata = presenter.rideMetadata(ride);

    return Semantics(
      button: true,
      label: '$statusLabel ride to $destination',
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSide),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('past-ride-${ride.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCancelled ? LucideIcons.x : LucideIcons.check,
                    color: statusColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.tertiaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 86),
                  child: Text(
                    presenter.fareLabel(ride),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  LucideIcons.chevron_right,
                  color: AppTheme.tertiaryColor,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
