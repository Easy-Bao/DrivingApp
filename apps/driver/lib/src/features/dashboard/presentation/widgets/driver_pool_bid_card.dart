import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/presentation/formatters/driver_value_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';

double? _distanceInKm(Map<String, dynamic> value) {
  final distance = value['distance_km'] ?? value['distance'];
  return distance is num && distance >= 0 ? distance.toDouble() : null;
}

int? remainingBidSeconds(Map<String, dynamic> bid) {
  final rawExpiry = valueAsString(bid['expires_at']);
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

class _BidCountdownHeader extends StatefulWidget {
  const _BidCountdownHeader({
    required this.bid,
    required this.hasSubmittedOffer,
    required this.bidId,
  });

  final Map<String, dynamic> bid;
  final bool hasSubmittedOffer;
  final String? bidId;

  @override
  State<_BidCountdownHeader> createState() => _BidCountdownHeaderState();
}

class _BidCountdownHeaderState extends State<_BidCountdownHeader> {
  Timer? _timer;
  int? _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = remainingBidSeconds(widget.bid);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _BidCountdownHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bid['expires_at'] != oldWidget.bid['expires_at']) {
      _remainingSeconds = remainingBidSeconds(widget.bid);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingSeconds != null && _remainingSeconds! > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final updated = remainingBidSeconds(widget.bid);
        if (updated != _remainingSeconds) {
          setState(() {
            _remainingSeconds = updated;
          });
        }
        if (updated == null || updated <= 0) {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = _remainingSeconds;
    return Row(
      children: [
        Text(
          widget.hasSubmittedOffer ? 'Awaiting confirmation' : 'Ride request',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                key: ValueKey('request-countdown-${widget.bidId}'),
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
    );
  }
}

class PoolBidCard extends StatelessWidget {
  const PoolBidCard({
    super.key,
    required this.bid,
    required this.submittingBidId,
    required this.onDecline,
    required this.onSubmitOffer,
  });

  final Map<String, dynamic> bid;
  final String? submittingBidId;
  final VoidCallback? onDecline;
  final VoidCallback? onSubmitOffer;

  @override
  Widget build(BuildContext context) {
    final pickup = bid['pickup_name']?.toString() ?? '—';
    final dropoff = bid['dropoff_name']?.toString() ?? '—';
    final fare = fareInPesos(bid);
    final displayedFare = _offerFare(bid, fare);
    final distance = _distanceInKm(bid);
    final bidId = valueAsString(bid['id']);
    final isSubmitting = bidId != null && submittingBidId == bidId;
    final hasSubmittedOffer = _hasPendingOffer(bid);
    final passengerNote = valueAsString(bid['passenger_note']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BidCountdownHeader(
            bid: bid,
            hasSubmittedOffer: hasSubmittedOffer,
            bidId: bidId,
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
                borderRadius: BorderRadius.circular(AppRadius.md),
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
              const SizedBox(width: AppSpacing.sm),
              Text(
                displayedFare == null ? '—' : formatPesoAmount(displayedFare),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (hasSubmittedOffer) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Text(
                'Waiting for the passenger to confirm you as their driver.',
                key: ValueKey('submitted-offer-status'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'The passenger confirms the driver before pickup.',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: submittingBidId != null ? null : onDecline,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSize.minimumTouchTarget),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: context.colorScheme.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                        : onSubmitOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.colorScheme.onPrimary,
                      elevation: 0,
                      minimumSize: const Size(0, AppSize.minimumTouchTarget),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                            'Accept fare',
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
        ],
      ),
    );
  }

  bool _hasPendingOffer(Map<String, dynamic> session) {
    if (session['local_offer_submitted'] == true) return true;
    final offers = session['offers'];
    if (offers is! List) return false;
    return offers.any(
      (offer) =>
          offer is Map &&
          valueAsString(offer['status'])?.toLowerCase() == 'pending',
    );
  }

  double? _offerFare(Map<String, dynamic> session, double? fallback) {
    final offers = session['offers'];
    if (offers is List) {
      for (final offer in offers) {
        if (offer is Map &&
            valueAsString(offer['status'])?.toLowerCase() == 'pending') {
          final amount = fareInPesos(Map<String, dynamic>.from(offer));
          if (amount != null) return amount;
        }
      }
    }
    return fallback;
  }
}
