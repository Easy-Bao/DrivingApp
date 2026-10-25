import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${rides.length} / ${DashboardState.maxActiveBookings} active bookings',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Open a booking to manage pickup or drop-off.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
            const SizedBox(height: AppSpacing.md),
          ],
          for (final ride in rides)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                leading: Icon(
                  ride.status == 'in_transit'
                      ? Icons.person
                      : Icons.person_pin_circle_outlined,
                ),
                title: Text(ride.passengerName ?? 'Passenger'),
                subtitle: Text(
                  '${switch (ride.status) {
                    'in_transit' => 'Onboard',
                    'arrived' => 'Waiting at pickup',
                    _ => 'Awaiting pickup',
                  }}\n${ride.status == 'in_transit' ? ride.dropoffName : ride.pickupName}',
                ),
                isThreeLine: true,
                trailing: openingRideId == ride.id
                    ? const SizedBox.square(
                        dimension: AppSpacing.lg,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: openingRideId == null ? () => onOpen(ride.id) : null,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
