import 'package:design_system/design_system.dart';
import 'package:driver/src/features/dashboard/presentation/formatters/driver_dashboard_value_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';

double? _distanceInKm(Map<String, dynamic> value) {
  final distance = value['distance_km'] ?? value['distance'];
  return distance is num && distance >= 0 ? distance.toDouble() : null;
}

int? remainingBidSeconds(Map<String, dynamic> bid) {
  final rawExpiry = dashboardValueAsString(bid['expires_at']);
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
    final fare = dashboardFareInPesos(bid);
    final distance = _distanceInKm(bid);
    final bidId = dashboardValueAsString(bid['id']);
    final isSubmitting = bidId != null && submittingBidId == bidId;
    final remainingSeconds = remainingBidSeconds(bid);
    final passengerNote = dashboardValueAsString(bid['passenger_note']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(EasyRideSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
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
                  borderRadius: BorderRadius.circular(EasyRideRadius.lg),
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
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CompactRouteTimeline(pickup: pickup, dropoff: dropoff),
          if (passengerNote != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(EasyRideRadius.md),
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
              Expanded(
                child: Text(
                  distance == null
                      ? 'Distance unavailable'
                      : '${DistanceFormatter.fromKilometers(distance)} away',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: EasyRideSpacing.sm),
              Text(
                fare == null ? '—' : formatPesoAmount(fare),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
                    minimumSize: const Size(0, EasyRideSize.minimumTouchTarget),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: context.colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                    ),
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
                    minimumSize: const Size(0, EasyRideSize.minimumTouchTarget),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                    ),
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

typedef DriverPoolBidCardWidget = DriverPoolBidCard;
