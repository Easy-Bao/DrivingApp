import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_core/shared_core.dart';
import 'package:design_system/design_system.dart';

double? _distanceInKm(Map<String, dynamic> value) {
  final distance = value['distance_km'] ?? value['distance'];
  return distance is num && distance >= 0 ? distance.toDouble() : null;
}

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
    final tripId = driverValueAsString(trip['id']);
    final isCompleting = tripId != null && isCompletingTrip;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(8),
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
                driverFareInPesos(trip) == null
                    ? '—'
                    : formatPesoAmount(driverFareInPesos(trip)!),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
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
              Text(
                driverValueAsString(trip['passenger_name']) ?? '—',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CompactRouteTimelineWidget(
            pickup: driverValueAsString(trip['pickup_name']) ?? '—',
            dropoff: driverValueAsString(trip['dropoff_name']) ?? '—',
          ),
          const SizedBox(height: 14),
          if (status == 'in_transit')
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onResume,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                        shape: const StadiumBorder(),
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
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isCompleting ? null : onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.semanticColors.success,
                        foregroundColor: context.semanticColors.onSuccess,
                        shape: const StadiumBorder(),
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
              height: 44,
              child: ElevatedButton(
                onPressed: isQueued ? null : onResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  shape: const StadiumBorder(),
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

int? remainingBidSeconds(Map<String, dynamic> bid) {
  final rawExpiry = driverValueAsString(bid['expires_at']);
  final expiresAt = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
  if (expiresAt == null) return null;
  final seconds = expiresAt.difference(DateTime.now()).inSeconds;
  return seconds.clamp(0, 3599).toInt();
}

String formatCountdown(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

class DriverPoolBidCard extends StatelessWidget {
  const DriverPoolBidCard({
    super.key,
    required this.bid,
    required this.submittingBidId,
    required this.onDecline,
    required this.onAccept,
  });

  final Map<String, dynamic> bid;
  final String? submittingBidId;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final pickup = bid['pickup_name']?.toString() ?? '—';
    final dropoff = bid['dropoff_name']?.toString() ?? '—';
    final fare = driverFareInPesos(bid);
    final distance = _distanceInKm(bid);
    final bidId = driverValueAsString(bid['id']);
    final isSubmitting = bidId != null && submittingBidId == bidId;
    final remainingSeconds = remainingBidSeconds(bid);
    final passengerNote = driverValueAsString(bid['passenger_note']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ride Request',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.clock_3, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      remainingSeconds == null
                          ? '—'
                          : formatCountdown(remainingSeconds),
                      key: ValueKey('request-countdown-$bidId'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CompactRouteTimelineWidget(pickup: pickup, dropoff: dropoff),
          if (passengerNote != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.message_square_text, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      passengerNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: context.colorScheme.outlineVariant),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                distance == null
                    ? 'Distance unavailable'
                    : '${DistanceFormatter.fromKilometers(distance)} away',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                fare == null ? '—' : formatPesoAmount(fare),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submittingBidId != null ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: context.colorScheme.outlineVariant),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: fare == null || submittingBidId != null
                      ? null
                      : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: context.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  child: isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverDashboardSectionLabel extends StatelessWidget {
  const DriverDashboardSectionLabel(this.label, {super.key});

  const DriverDashboardSectionLabel.activeRides({
    required int activeRideCount,
    super.key,
  }) : label = 'Your active rides ($activeRideCount/$maximumActiveRides)';

  static const maximumActiveRides = 5;

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
