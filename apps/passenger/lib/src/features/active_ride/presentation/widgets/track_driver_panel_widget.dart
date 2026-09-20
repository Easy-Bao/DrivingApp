import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

class const TrackDriverPanelWidget({
  super.key,
  required this.ride,
  required this.statusTitle,
  required this.statusSubtitle,
  required this.etaText,
  this.driverName,
  this.vehicleSummary,
  required this.unreadChatMessagesCount,
  this.showContactActions = true,
  this.isCancellingTrip = false,
  required this.onCallDriverPressed,
  required this.onChatDriverPressed,
  required this.onEmergencyPressed,
  required this.onCancelTripPressed,
}) extends StatelessWidget {
  final RideHistory ride;
  final String statusTitle;
  final String statusSubtitle;
  final String etaText;
  final String? driverName;
  final String? vehicleSummary;
  final int unreadChatMessagesCount;
  final bool showContactActions;
  final bool isCancellingTrip;
  final VoidCallback onCallDriverPressed;
  final VoidCallback onChatDriverPressed;
  final VoidCallback onEmergencyPressed;
  final VoidCallback onCancelTripPressed;

  @override
  Widget build(BuildContext context) {
    final resolvedDriverName = driverName?.trim().isNotEmpty == true
        ? driverName!.trim()
        : ride.displayDriverName;
    final resolvedVehicleSummary = vehicleSummary?.trim().isNotEmpty == true
        ? vehicleSummary!.trim()
        : ride.displayVehicleSummary;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EasyRideRadius.sheet),
        ),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(
        EasyRideSpacing.lg,
        10,
        EasyRideSpacing.lg,
        14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  etaText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(EasyRideRadius.lg),
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                const AppNetworkImageWidget(
                  imageUrl: null,
                  width: 38,
                  height: 38,
                  fallbackIcon: LucideIcons.user,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Driver',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        resolvedDriverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        resolvedVehicleSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showContactActions) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.phone,
                    label: 'Call Driver',
                    filled: true,
                    onTap: onCallDriverPressed,
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: 'Chat with driver',
                  child: Badge(
                    isLabelVisible: unreadChatMessagesCount > 0,
                    label: Text('$unreadChatMessagesCount'),
                    backgroundColor: context.colorScheme.error,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colorScheme.outlineVariant,
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Chat with driver',
                        onPressed: onChatDriverPressed,
                        constraints: const BoxConstraints(
                          minWidth: EasyRideSize.minimumTouchTarget,
                          minHeight: EasyRideSize.minimumTouchTarget,
                        ),
                        icon: const Icon(LucideIcons.message_circle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: EasyRideSize.minimumTouchTarget,
              child: OutlinedButton.icon(
                onPressed: onEmergencyPressed,
                icon: const Icon(Icons.emergency_outlined),
                label: const Text('Emergency SOS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colorScheme.error,
                  side: BorderSide(color: context.colorScheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: EasyRideSize.minimumTouchTarget,
              child: TextButton(
                onPressed: isCancellingTrip ? null : onCancelTripPressed,
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                  ),
                ),
                child: isCancellingTrip
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colorScheme.error,
                        ),
                      )
                    : const Text('Cancel ride'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class const _ActionButton({
  required this.icon,
  required this.label,
  required this.onTap,
  this.filled = false,
}) extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? context.colorScheme.primary
        : context.colorScheme.surfaceContainerHighest;
    final foreground = filled
        ? context.colorScheme.onPrimary
        : context.colorScheme.onSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(EasyRideRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        child: Container(
          height: EasyRideSize.minimumTouchTarget,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EasyRideRadius.lg),
            border: filled
                ? null
                : Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
