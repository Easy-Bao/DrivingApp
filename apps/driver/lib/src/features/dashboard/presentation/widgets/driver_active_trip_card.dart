import 'package:design_system/design_system.dart';
import 'package:driver/src/features/dashboard/presentation/formatters/driver_dashboard_value_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';

class DriverActiveTripCard extends StatelessWidget {
  const DriverActiveTripCard({
    super.key,
    required this.trip,
    required this.queueIndex,
    required this.hasCurrentTransitRide,
    required this.isCompletingTrip,
    required this.onResume,
    required this.onComplete,
  });

  final Map<String, dynamic> trip;
  final int queueIndex;
  final bool hasCurrentTransitRide;
  final bool isCompletingTrip;
  final VoidCallback onResume;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final status = trip['status'] as String? ?? 'accepted';
    String statusLabel = 'Heading To Passenger';
    Color statusColor = context.colorScheme.primary;
    if (status == 'arrived') {
      statusLabel = 'Waiting For Passenger';
      statusColor = context.colorScheme.secondaryContainer;
    } else if (status == 'in_transit') {
      statusLabel = 'Driving Passenger';
      statusColor = context.semanticColors.success;
    }
    final hasCurrentTransitRide = this.hasCurrentTransitRide;
    final isQueued = hasCurrentTransitRide && status != 'in_transit';
    final tripId = dashboardValueAsString(trip['id']);
    final isCompleting = tripId != null && isCompletingTrip;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(EasyRideSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
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
                  borderRadius: BorderRadius.circular(EasyRideRadius.md),
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
                dashboardFareInPesos(trip) == null
                    ? '—'
                    : formatPesoAmount(dashboardFareInPesos(trip)!),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (isQueued) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Queued passenger ${queueIndex + 1} • Start after the current trip',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
                  dashboardValueAsString(trip['passenger_name']) ?? '—',
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
            pickup: dashboardValueAsString(trip['pickup_name']) ?? '—',
            dropoff: dashboardValueAsString(trip['dropoff_name']) ?? '—',
          ),
          const SizedBox(height: 14),
          if (status == 'in_transit')
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: EasyRideSize.minimumTouchTarget,
                    child: ElevatedButton(
                      onPressed: onResume,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            EasyRideRadius.lg,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Go to Trip Flow',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: EasyRideSize.minimumTouchTarget,
                    child: ElevatedButton(
                      onPressed: isCompleting ? null : onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.semanticColors.success,
                        foregroundColor: context.semanticColors.onSuccess,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            EasyRideRadius.lg,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: isCompleting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.semanticColors.onSuccess,
                              ),
                            )
                          : const Text(
                              'Complete Trip',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: EasyRideSize.minimumTouchTarget,
              child: ElevatedButton(
                onPressed: isQueued ? null : onResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Go to Trip Flow',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

typedef DriverActiveTripCardWidget = DriverActiveTripCard;
