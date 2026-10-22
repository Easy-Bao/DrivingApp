import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';

class ActiveTripCard extends StatelessWidget {
  const ActiveTripCard({super.key, required this.trip, required this.onResume});

  final RideSnapshot trip;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final status = trip.status;
    String statusLabel = 'Heading To Passenger';
    Color statusColor = context.colorScheme.primary;
    if (status == 'arrived') {
      statusLabel = 'Waiting For Passenger';
      statusColor = context.colorScheme.secondaryContainer;
    } else if (status == 'in_transit') {
      statusLabel = 'Driving Passenger';
      statusColor = context.semanticColors.success;
    }
    final fare = trip.farePesos;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor == context.colorScheme.secondaryContainer
                        ? context.colorScheme.onSurface
                        : statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                fare == null ? '—' : formatPesoAmount(fare),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (trip.bookingReference.isNotEmpty) ...[
            const SizedBox(height: 8),
            TripReference(id: trip.bookingReference, compact: true),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.user,
                size: 14,
                color: context.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.passengerName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CompactRouteTimeline(
            pickup: trip.pickupName,
            dropoff: trip.dropoffName,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: AppSize.minimumTouchTarget,
            child: ElevatedButton.icon(
              onPressed: onResume,
              icon: const Icon(LucideIcons.navigation, size: 18),
              label: Text(
                status == 'in_transit'
                    ? 'Continue Navigation'
                    : 'Open Trip Details',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: context.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
