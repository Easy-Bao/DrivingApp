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
  required this.onCallDriverPressed,
  required this.onChatDriverPressed,
  required this.onEmergencyPressed,
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
  final VoidCallback onCallDriverPressed;
  final VoidCallback onChatDriverPressed;
  final VoidCallback onEmergencyPressed;
  final VoidCallback onReportDriverPressed;
  final VoidCallback onCancelTripPressed;

  @override
  Widget build(BuildContext context) {
    final resolvedDriverName = driverName?.trim().isNotEmpty == true
        ? driverName!.trim()
        : ride.displayDriverName;
    final resolvedVehicleSummary = vehicleSummary?.trim().isNotEmpty == true
        ? vehicleSummary!.trim()
        : ride.displayVehicleSummary;
    final resolvedBadgeText = statusBadgeText?.trim().isNotEmpty == true
        ? statusBadgeText!.trim()
        : (isInTransit == true || ride.status == 'in_transit')
        ? 'ON TRIP'
        : ride.status == 'arrived'
        ? 'ARRIVED'
        : 'EN ROUTE';
    final resolvedRating = driverRating?.trim().isNotEmpty == true
        ? driverRating!.trim()
        : ride.displayDriverRating;
    final liveIsInTransit =
        isInTransit ??
        (resolvedBadgeText.toUpperCase() == 'ON TRIP' ||
            ride.status == 'in_transit');
    final showCancelAction = !liveIsInTransit;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.8,
                ),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  statusTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(text: resolvedBadgeText),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            statusSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _DriverCard(
            driverName: resolvedDriverName,
            vehicleSummary: resolvedVehicleSummary,
            rating: resolvedRating,
            imageUrl: driverAvatarUrl,
            showContactActions: showContactActions,
            unreadChatMessagesCount: unreadChatMessagesCount,
            onCallPressed: onCallDriverPressed,
            onChatPressed: onChatDriverPressed,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onEmergencyPressed,
                    icon: Icon(
                      LucideIcons.bell_ring,
                      size: 18,
                      color: context.colorScheme.error,
                    ),
                    label: Text(
                      'Emergency SOS',
                      style: TextStyle(
                        color: context.colorScheme.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: context.colorScheme.errorContainer,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onReportDriverPressed,
                    icon: Icon(
                      LucideIcons.triangle_alert,
                      size: 18,
                      color: context.semanticColors.warning,
                    ),
                    label: Text(
                      'Report Issue',
                      style: TextStyle(
                        color: context.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          context.colorScheme.surfaceContainerHighest,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showCancelAction) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: isCancellingTrip ? null : onCancelTripPressed,
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.error,
                  visualDensity: VisualDensity.compact,
                ),
                child: isCancellingTrip
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colorScheme.error,
                        ),
                      )
                    : const Text(
                        'Cancel ride',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class const _StatusBadge({required this.text}) extends StatelessWidget {
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.semanticColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.semanticColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.semanticColors.success,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class const _DriverCard({
  required this.driverName,
  required this.vehicleSummary,
  this.rating,
  this.imageUrl,
  required this.showContactActions,
  required this.unreadChatMessagesCount,
  required this.onCallPressed,
  required this.onChatPressed,
}) extends StatelessWidget {
  final String driverName;
  final String vehicleSummary;
  final String? rating;
  final String? imageUrl;
  final bool showContactActions;
  final int unreadChatMessagesCount;
  final VoidCallback onCallPressed;
  final VoidCallback onChatPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                AppNetworkImage(
                  imageUrl: imageUrl,
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(99),
                  fallbackIcon: LucideIcons.user,
                ),
                if (rating != null && rating!.trim().isNotEmpty)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: context.colorScheme.shadow.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: context.semanticColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vehicleSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.bike,
                      size: 15,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showContactActions) ...[
            const SizedBox(width: 8),
            _ContactButton(
              icon: LucideIcons.phone,
              label: 'Call',
              onTap: onCallPressed,
            ),
            const SizedBox(width: 10),
            _ContactButton(
              icon: LucideIcons.message_square,
              label: 'Message',
              badgeCount: unreadChatMessagesCount,
              onTap: onChatPressed,
            ),
          ],
        ],
      ),
    );
  }
}

class const _ContactButton({
  required this.icon,
  required this.label,
  this.badgeCount = 0,
  required this.onTap,
}) extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: label,
      child: Material(
        color: context.colorScheme.surface,
        shape: const CircleBorder(),
        elevation: 0.5,
        shadowColor: context.colorScheme.shadow.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: context.colorScheme.primary),
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badgeCount > 0)
          Badge(
            label: Text('$badgeCount'),
            backgroundColor: context.colorScheme.error,
            child: button,
          )
        else
          button,
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
