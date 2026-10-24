import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';

class const TrackDriverPanel({
  super.key,
  required this.ride,
  required this.statusTitle,
  required this.statusSubtitle,
  required this.etaText,
  this.statusBadgeText,
  this.driverName,
  this.vehicleSummary,
  this.driverRating,
  this.driverAvatarUrl,
  required this.unreadChatMessagesCount,
  this.showContactActions = true,
  this.isCancellingTrip = false,
  this.isInTransit,
  required this.onChatDriverPressed,
  required this.onReportDriverPressed,
  required this.onCancelTripPressed,
}) extends StatelessWidget {
  final RideSnapshot ride;
  final String statusTitle;
  final String statusSubtitle;
  final String etaText;
  final String? statusBadgeText;
  final String? driverName;
  final String? vehicleSummary;
  final String? driverRating;
  final String? driverAvatarUrl;
  final int unreadChatMessagesCount;
  final bool showContactActions;
  final bool isCancellingTrip;
  final bool? isInTransit;
  final VoidCallback onChatDriverPressed;
  final VoidCallback onReportDriverPressed;
  final VoidCallback onCancelTripPressed;

  @override
  Widget build(BuildContext context) {
    final name = driverName?.trim().isNotEmpty == true
        ? driverName!.trim()
        : ride.displayDriverName;
    final vehicle = vehicleSummary?.trim().isNotEmpty == true
        ? vehicleSummary!.trim()
        : ride.displayVehicleSummary;
    final rating = driverRating?.trim().isNotEmpty == true
        ? driverRating!.trim()
        : ride.displayDriverRating;
    final onTrip =
        isInTransit ??
        (ride.status == 'in_transit' || statusBadgeText == 'ON TRIP');

    return Material(
      color: context.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(statusTitle, style: context.textStyles.titleLarge),
                if (etaText.trim().isNotEmpty)
                  Text(
                    etaText,
                    key: const ValueKey('live-trip-eta'),
                    style: context.textStyles.titleMedium,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              statusSubtitle,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                AppNetworkImage(
                  imageUrl: driverAvatarUrl,
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(24),
                  fallbackIcon: LucideIcons.user_round,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: context.textStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        vehicle,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (rating != null && rating.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: context.semanticColors.rating,
                            ),
                            const SizedBox(width: 4),
                            Text(rating, style: context.textStyles.bodySmall),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (showContactActions) ...[
              const SizedBox(height: 16),
              Badge(
                isLabelVisible: unreadChatMessagesCount > 0,
                label: Text('$unreadChatMessagesCount'),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onChatDriverPressed,
                    icon: const Icon(LucideIcons.message_circle, size: 20),
                    label: const Text('Message driver'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onReportDriverPressed,
                icon: const Icon(LucideIcons.flag, size: 18),
                label: const Text('Report issue'),
              ),
            ),
            if (!onTrip)
              TextButton(
                onPressed: isCancellingTrip ? null : onCancelTripPressed,
                child: Text(isCancellingTrip ? 'Cancelling…' : 'Cancel ride'),
              ),
          ],
        ),
      ),
    );
  }
}
